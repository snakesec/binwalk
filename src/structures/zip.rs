use crate::structures::common::{self, StructureError};

#[derive(Debug, Default, Clone)]
pub struct ZipFileHeader {
    pub data_size: usize,
    pub header_size: usize,
    pub total_size: usize,
    pub version_major: usize,
    pub version_minor: usize,
}

/// Validate a ZIP file header
pub fn parse_zip_header(zip_data: &[u8]) -> Result<ZipFileHeader, StructureError> {
    // Unused flag bits
    const UNUSED_FLAGS_MASK: usize = 0b11010111_10000000;

    // Encrypted compression type
    const COMPRESSION_ENCRYPTED: usize = 99;

    let zip_local_file_structure = vec![
        ("magic", "u32"),
        ("version", "u16"),
        ("flags", "u16"),
        ("compression", "u16"),
        ("modification_time", "u16"),
        ("modification_date", "u16"),
        ("crc", "u32"),
        ("compressed_size", "u32"),
        ("uncompressed_size", "u32"),
        ("file_name_len", "u16"),
        ("extra_field_len", "u16"),
    ];

    let allowed_compression_methods: Vec<usize> = vec![
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        8,
        9,
        10,
        12,
        14,
        18,
        19,
        20,
        93,
        94,
        95,
        96,
        97,
        98,
        COMPRESSION_ENCRYPTED,
    ];

    let mut result = ZipFileHeader {
        ..Default::default()
    };

    // Parse the ZIP local file structure
    if let Ok(zip_local_file_header) = common::parse(zip_data, &zip_local_file_structure, "little")
    {
        // Unused/reserved flag bits should be 0
        if (zip_local_file_header["flags"] & UNUSED_FLAGS_MASK) == 0 {
            // Specified compression method should be one of the defined ZIP compression methods
            if allowed_compression_methods.contains(&zip_local_file_header["compression"]) {
                result.version_major = zip_local_file_header["version"] / 10;
                result.version_minor = zip_local_file_header["version"] % 10;
                result.header_size = common::size(&zip_local_file_structure)
                    + zip_local_file_header["file_name_len"]
                    + zip_local_file_header["extra_field_len"];
                result.data_size = if zip_local_file_header["compressed_size"] > 0 {
                    zip_local_file_header["compressed_size"]
                } else {
                    zip_local_file_header["uncompressed_size"]
                };
                result.total_size = result.header_size + result.data_size;
                return Ok(result);
            }
        }
    }

    Err(StructureError)
}

/// Stores info about a ZIP end-of-central-directory header
#[derive(Debug, Default, Clone)]
pub struct ZipEOCDHeader {
    pub size: usize,
    pub file_count: usize,
}

/// Parse a ZIP end-of-central-directory header
pub fn parse_eocd_header(eocd_data: &[u8]) -> Result<ZipEOCDHeader, StructureError> {
    let zip_eocd_structure = vec![
        ("magic", "u32"),
        ("disk_number", "u16"),
        ("central_directory_disk_number", "u16"),
        ("central_directory_disk_entries", "u16"),
        ("central_directory_total_entries", "u16"),
        ("central_directory_size", "u32"),
        ("central_directory_offset", "u32"),
        ("comment_length", "u16"),
    ];

    // Parse the EOCD header
    if let Ok(zip_eocd_header) = common::parse(eocd_data, &zip_eocd_structure, "little") {
        // Assume there is only one "disk", so disk entries and total entries should be the same, and the ZIP archive should contain at least one file
        if zip_eocd_header["central_directory_disk_entries"]
            == zip_eocd_header["central_directory_total_entries"]
            && zip_eocd_header["central_directory_total_entries"] > 0
        {
            // An optional comment may follow the EOCD header; include the comment length in the offset of the ZIP EOF offset
            let zip_eof: usize =
                common::size(&zip_eocd_structure) + zip_eocd_header["comment_length"];

            return Ok(ZipEOCDHeader {
                size: zip_eof,
                file_count: zip_eocd_header["central_directory_total_entries"],
            });
        }
    }

    Err(StructureError)
}
