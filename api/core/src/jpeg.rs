//! Just enough JPEG reading to check what the app sends: the format and the
//! size, read from the frame header without decoding the image.

/// Width and height of a JPEG, or None if `bytes` isn't one.
pub fn dimensions(bytes: &[u8]) -> Option<(u16, u16)> {
    if bytes.get(..2)? != [0xFF, 0xD8] {
        return None;
    }
    let mut i = 2;
    loop {
        // Each segment starts with 0xFF, possibly padded with more 0xFF.
        if *bytes.get(i)? != 0xFF {
            return None;
        }
        while *bytes.get(i)? == 0xFF {
            i += 1;
        }
        let marker = *bytes.get(i)?;
        i += 1;
        // Markers without a length: restart markers and TEM.
        if (0xD0..=0xD7).contains(&marker) || marker == 0x01 {
            continue;
        }
        // End of image or start of scan before any frame header.
        if marker == 0xD9 || marker == 0xDA {
            return None;
        }
        let length = u16::from_be_bytes([*bytes.get(i)?, *bytes.get(i + 1)?]) as usize;
        if length < 2 {
            return None;
        }
        // Start of frame: every SOFn except DHT (C4), JPG (C8) and DAC (CC).
        if (0xC0..=0xCF).contains(&marker) && ![0xC4, 0xC8, 0xCC].contains(&marker) {
            let height = u16::from_be_bytes([*bytes.get(i + 3)?, *bytes.get(i + 4)?]);
            let width = u16::from_be_bytes([*bytes.get(i + 5)?, *bytes.get(i + 6)?]);
            return Some((width, height));
        }
        i += length;
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    /// The headers of a baseline JPEG of the given size, as far as
    /// [dimensions] reads.
    pub(crate) fn jpeg(width: u16, height: u16) -> Vec<u8> {
        let mut bytes = vec![0xFF, 0xD8];
        // An APP0 segment first, as cameras write.
        bytes.extend([0xFF, 0xE0, 0x00, 0x10]);
        bytes.extend(b"JFIF\0\x01\x01\0\0\x01\0\x01\0\0");
        // SOF0: length, precision, height, width, one component.
        bytes.extend([0xFF, 0xC0, 0x00, 0x0B, 0x08]);
        bytes.extend(height.to_be_bytes());
        bytes.extend(width.to_be_bytes());
        bytes.extend([0x01, 0x01, 0x11, 0x00]);
        bytes.extend([0xFF, 0xD9]);
        bytes
    }

    #[test]
    fn reads_the_frame_size() {
        assert_eq!(dimensions(&jpeg(512, 384)), Some((512, 384)));
    }

    #[test]
    fn rejects_other_formats() {
        assert_eq!(dimensions(b"\x89PNG\r\n\x1a\n"), None);
        assert_eq!(dimensions(b""), None);
        assert_eq!(dimensions(&[0xFF, 0xD8, 0xFF]), None);
        // A JPEG cut off before its frame header.
        assert_eq!(dimensions(&jpeg(512, 384)[..10]), None);
    }
}
