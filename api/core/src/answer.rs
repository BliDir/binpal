//! Reading the model's answer. Nothing it says reaches the app unchecked:
//! the item must be one the app sent, and the category one the bundle has.

use serde::{Deserialize, Serialize};

use crate::catalog::CategoryGuide;
use crate::cost::{Usage, WorkersAiUsage};
use crate::request::Candidate;

/// What the app gets back. Instructions come from the app's own bundle.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Answer {
    pub item_id: Option<String>,
    pub category: Option<String>,
    pub confidence: f64,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Outcome {
    Answered(Answer),
    /// No usable answer; the app keeps its on-device candidates.
    NoAnswer(&'static str),
}

impl Outcome {
    /// Short name for the tuning log.
    pub fn label(&self) -> &'static str {
        match self {
            Self::Answered(Answer {
                item_id: Some(_), ..
            }) => "item",
            Self::Answered(_) => "category",
            Self::NoAnswer(reason) => reason,
        }
    }
}

#[derive(Deserialize)]
struct Message {
    #[serde(default)]
    content: Vec<Block>,
    stop_reason: Option<String>,
    #[serde(default)]
    usage: Usage,
}

#[derive(Deserialize)]
struct Block {
    #[serde(rename = "type")]
    kind: String,
    #[serde(default)]
    text: Option<String>,
}

#[derive(Deserialize)]
struct RawAnswer {
    item_id: Option<String>,
    category: Option<String>,
    confidence: f64,
}

/// The outcome and token usage of a Messages API response. Usage is read even
/// when there is no answer, since those tokens are billed too.
pub fn parse_response(
    body: &[u8],
    candidates: &[Candidate],
    guide: &CategoryGuide,
) -> Result<(Outcome, Usage), String> {
    let message: Message = serde_json::from_slice(body).map_err(|e| format!("response: {e}"))?;
    let usage = message.usage;
    match message.stop_reason.as_deref() {
        Some("refusal") => return Ok((Outcome::NoAnswer("refusal"), usage)),
        Some("max_tokens") => return Ok((Outcome::NoAnswer("max_tokens"), usage)),
        _ => {}
    }
    // Content may start with thinking blocks; the answer is the text block.
    let Some(text) = message
        .content
        .iter()
        .find(|b| b.kind == "text")
        .and_then(|b| b.text.as_deref())
    else {
        return Ok((Outcome::NoAnswer("no_text"), usage));
    };
    Ok((check(text, candidates, guide), usage))
}

/// The checked answer in a model's text: the item must be one of the
/// candidates and the category one the bundle has. Takes the outermost JSON
/// object, in case a model wraps it in prose or a code fence.
fn check(text: &str, candidates: &[Candidate], guide: &CategoryGuide) -> Outcome {
    let json = match (text.find('{'), text.rfind('}')) {
        (Some(start), Some(end)) if start < end => &text[start..=end],
        _ => return Outcome::NoAnswer("unparseable"),
    };
    let Ok(raw) = serde_json::from_str::<RawAnswer>(json) else {
        return Outcome::NoAnswer("unparseable");
    };

    let candidate = raw
        .item_id
        .as_deref()
        .and_then(|id| candidates.iter().find(|c| c.item_id == id));
    let category = match candidate {
        // The bundle decides a known item's category, not the model.
        Some(c) => Some(c.category.clone()),
        None => raw.category.filter(|id| guide.has(id)),
    };
    if candidate.is_none() && category.is_none() {
        return Outcome::NoAnswer("unknown");
    }
    let confidence = if raw.confidence.is_finite() {
        raw.confidence.clamp(0.0, 1.0)
    } else {
        0.0
    };
    Outcome::Answered(Answer {
        item_id: candidate.map(|c| c.item_id.clone()),
        category,
        confidence,
    })
}

#[derive(Deserialize)]
struct ChatOutput {
    #[serde(default)]
    choices: Vec<Choice>,
    /// Older Workers AI text models answer in `response` instead.
    #[serde(default)]
    response: Option<serde_json::Value>,
    #[serde(default)]
    usage: WorkersAiUsage,
}

#[derive(Deserialize)]
struct Choice {
    message: ChatMessage,
    finish_reason: Option<String>,
}

#[derive(Deserialize)]
struct ChatMessage {
    content: Option<String>,
}

/// The outcome and token usage of a Workers AI chat response.
pub fn parse_workers_ai(
    output: &serde_json::Value,
    candidates: &[Candidate],
    guide: &CategoryGuide,
) -> Result<(Outcome, WorkersAiUsage), String> {
    let output = ChatOutput::deserialize(output).map_err(|e| format!("Workers AI output: {e}"))?;
    let usage = output.usage;
    let text = match (output.choices.first(), output.response) {
        (Some(choice), _) => {
            match choice.finish_reason.as_deref() {
                Some("length") => return Ok((Outcome::NoAnswer("max_tokens"), usage)),
                Some("content_filter") => return Ok((Outcome::NoAnswer("refusal"), usage)),
                _ => {}
            }
            choice.message.content.clone()
        }
        // JSON mode may hand back the object itself rather than its text.
        (None, Some(serde_json::Value::String(text))) => Some(text),
        (None, Some(object @ serde_json::Value::Object(_))) => Some(object.to_string()),
        _ => None,
    };
    let Some(text) = text else {
        return Ok((Outcome::NoAnswer("no_text"), usage));
    };
    Ok((check(&text, candidates, guide), usage))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::catalog::tests::yokohama;
    use serde_json::json;

    fn candidates() -> Vec<Candidate> {
        vec![
            Candidate {
                item_id: "yokohama-10".into(),
                name_ja: "かさ(骨が金属製)".into(),
                name_en: "Umbrella (metal ribs)".into(),
                category: "kinzoku".into(),
            },
            Candidate {
                item_id: "yokohama-11".into(),
                name_ja: "かさ(骨がプラスチック製)".into(),
                name_en: "Umbrella (plastic ribs)".into(),
                category: "moyasu".into(),
            },
        ]
    }

    fn response(answer: serde_json::Value, stop: &str) -> Vec<u8> {
        serde_json::to_vec(&json!({
            "id": "msg_1",
            "type": "message",
            "role": "assistant",
            "model": "claude-haiku-5-5",
            "content": [
                {"type": "thinking", "thinking": "", "signature": "x"},
                {"type": "text", "text": answer.to_string()},
            ],
            "stop_reason": stop,
            "usage": {
                "input_tokens": 1200, "output_tokens": 40,
                "cache_creation_input_tokens": 0, "cache_read_input_tokens": 2100,
            },
        }))
        .unwrap()
    }

    fn parse(answer: serde_json::Value) -> Outcome {
        parse_response(&response(answer, "end_turn"), &candidates(), &yokohama())
            .unwrap()
            .0
    }

    #[test]
    fn a_candidate_takes_its_category_from_the_bundle() {
        let outcome =
            parse(json!({"item_id": "yokohama-10", "category": "moyasu", "confidence": 0.9}));
        assert_eq!(
            outcome,
            Outcome::Answered(Answer {
                item_id: Some("yokohama-10".into()),
                category: Some("kinzoku".into()),
                confidence: 0.9,
            })
        );
    }

    #[test]
    fn an_invented_item_is_dropped_but_a_real_category_is_kept() {
        let outcome =
            parse(json!({"item_id": "yokohama-999", "category": "plastic", "confidence": 0.6}));
        assert_eq!(
            outcome,
            Outcome::Answered(Answer {
                item_id: None,
                category: Some("plastic".into()),
                confidence: 0.6,
            })
        );
        assert_eq!(outcome.label(), "category");
    }

    #[test]
    fn nothing_usable_is_no_answer() {
        let outcome = parse(json!({"item_id": null, "category": "recycling", "confidence": 0.3}));
        assert_eq!(outcome, Outcome::NoAnswer("unknown"));
    }

    #[test]
    fn confidence_is_kept_between_0_and_1() {
        let Outcome::Answered(answer) =
            parse(json!({"item_id": "yokohama-11", "category": null, "confidence": 7}))
        else {
            panic!()
        };
        assert_eq!(answer.confidence, 1.0);
    }

    #[test]
    fn refusals_and_cut_off_answers_still_report_usage() {
        let (outcome, usage) =
            parse_response(&response(json!({}), "refusal"), &candidates(), &yokohama()).unwrap();
        assert_eq!(outcome, Outcome::NoAnswer("refusal"));
        assert_eq!(usage.cache_read_input_tokens, 2100);

        let (outcome, _) = parse_response(
            &response(json!({}), "max_tokens"),
            &candidates(),
            &yokohama(),
        )
        .unwrap();
        assert_eq!(outcome, Outcome::NoAnswer("max_tokens"));
    }

    #[test]
    fn workers_ai_chat_output_is_checked_the_same_way() {
        let output = json!({
            "id": "chatcmpl-1",
            "object": "chat.completion",
            "created": 0,
            "model": "@cf/qwen/qwen3.8-27b",
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content":
                    "```json\n{\"item_id\": \"yokohama-10\", \"category\": \"moyasu\", \"confidence\": 0.7}\n```"},
                "finish_reason": "stop",
                "logprobs": null,
            }],
            "usage": {"prompt_tokens": 1300, "completion_tokens": 30, "total_tokens": 1330},
        });
        let (outcome, usage) = parse_workers_ai(&output, &candidates(), &yokohama()).unwrap();
        assert_eq!(
            outcome,
            Outcome::Answered(Answer {
                item_id: Some("yokohama-10".into()),
                category: Some("kinzoku".into()),
                confidence: 0.7,
            })
        );
        assert_eq!(usage.prompt_tokens, 1300);
    }

    #[test]
    fn workers_ai_older_shapes_and_cut_off_answers() {
        let object =
            json!({"response": {"item_id": null, "category": "plastic", "confidence": 0.5}});
        let (outcome, _) = parse_workers_ai(&object, &candidates(), &yokohama()).unwrap();
        assert_eq!(outcome.label(), "category");

        let cut = json!({
            "choices": [{"message": {"content": "{\"item_id\": \"yoko"}, "finish_reason": "length"}],
            "usage": {"prompt_tokens": 1300, "completion_tokens": 256, "total_tokens": 1556},
        });
        let (outcome, usage) = parse_workers_ai(&cut, &candidates(), &yokohama()).unwrap();
        assert_eq!(outcome, Outcome::NoAnswer("max_tokens"));
        assert_eq!(usage.completion_tokens, 256);

        assert!(parse_workers_ai(&json!("not an object"), &candidates(), &yokohama()).is_err());
        let empty = parse_workers_ai(&json!({}), &candidates(), &yokohama()).unwrap();
        assert_eq!(empty.0, Outcome::NoAnswer("no_text"));
    }

    #[test]
    fn text_that_is_not_the_schema() {
        let bytes = serde_json::to_vec(&json!({
            "content": [{"type": "text", "text": "It's an umbrella."}],
            "stop_reason": "end_turn",
            "usage": {"input_tokens": 10, "output_tokens": 5},
        }))
        .unwrap();
        let (outcome, usage) = parse_response(&bytes, &candidates(), &yokohama()).unwrap();
        assert_eq!(outcome, Outcome::NoAnswer("unparseable"));
        assert_eq!(usage.input_tokens, 10);
    }
}
