public enum MimeFamily {
    TEXT("Text file"), PAGE("HTML or XML static page"), SCRIPT("Dynamic HTML page or Script file"),
        PL("Dynamic Perl Script file"), PHP("Dynamic PHP Script file"), IMAGE("Image"),
        DOCUMENT("Document"), PACKAGE("Package"), ARCHIVE("Archive"), AUDIO("Audio file"),
        VIDEO("Video file"), JSCRIPT("JavaScript file"), JSON("JavaScript Object Notation file"),
        VBS("Visual Basic script"), CONF("Config file"), CSS("Cascading Style Sheet file"),
        XSL("Extensible Stylesheet Language file"), RUNTIME("Binary runtime"), LIBRARY("Binary library"),
        SWF("Adobe Flash Animation"), FLV("Adobe Flash Video"), DTD("Document Type Definition"),
        CSV("Comma Separated Value file"), JNLP("Java Web Start launch file"), LIT("Microsoft Reader e-book"),
        SVG("Scalable Vector Graphics"), AI("Adobe Illustrator file"), PHSHOP("Adobe Photoshop image file"),
        TTF("TrueType scalable font file"), FON("Font file"), PDF("Adobe Acrobat file"),
        DOTNET("Dot Net Dynamic Script or File"), MDB("MS Database Object"), CRYSTAL("Crystal Reports data or file"),
        OOFFICE("Open Office Document"), LIBREOFFICE("LibreOffice Document"), ENCRYPT("Encrypted document"),
        GPX("GPS Exchange Format file"), DISKIMAGE("Disc and media file extensions"), VM("Virtual Machine image"),
        TORRENT("BitTorrent File"), GIS("GIS File"), EBOOK("Ebook File"), RSS("RSS/Atom Feed"), FLASH("Adobe Flash");

    private final String description;
    MimeFamily(String description) { this.description = description; }
    public String getDescription() { return description; }
}

    public enum MimeType {
        // Text
            TXT("txt", MimeFamily.TEXT, "d"), LOG("log", MimeFamily.TEXT, "d"),
            // Pages
            CHM("chm", MimeFamily.PAGE, "p"), HTML("html", MimeFamily.PAGE, "p"),
            HTM("htm", MimeFamily.PAGE, "p"), XML("xml", MimeFamily.PAGE, "p"),
            // Scripts / Dynamic
            ASP("asp", MimeFamily.SCRIPT, "p"), PHP("php", MimeFamily.PHP, "p"),
            JS("js", MimeFamily.JSCRIPT, "p"), PL("pl", MimeFamily.PL, "p"),
            PY("py", MimeFamily.SCRIPT, "p"), RSS("rss", MimeFamily.RSS, "p"),
            // Images
            GIF("gif", MimeFamily.IMAGE, "i"), PNG("png", MimeFamily.IMAGE, "i"),
            JPG("jpg", MimeFamily.IMAGE, "i"), WEBP("webp", MimeFamily.IMAGE, "i"),
            // Documents
            DOCX("docx", MimeFamily.DOCUMENT, "d"), PDF("pdf", MimeFamily.PDF, "d"),
            XLSX("xlsx", MimeFamily.DOCUMENT, "d"), ODT("odt", MimeFamily.LIBREOFFICE, "d"),
            // Archives
            ZIP("zip", MimeFamily.ARCHIVE, "d"), TAR("tar", MimeFamily.ARCHIVE, "d"),
            GZ("gz", MimeFamily.ARCHIVE, "d"), JAR("jar", MimeFamily.ARCHIVE, "d"),
            // Media
            MP3("mp3", MimeFamily.AUDIO, "d"), WAV("wav", MimeFamily.AUDIO, "d"),
            MP4("mp4", MimeFamily.VIDEO, "d"), MOV("mov", MimeFamily.VIDEO, "d"),
            // System / VM
            EXE("exe", MimeFamily.RUNTIME, "d"), ISO("iso", MimeFamily.DISKIMAGE, "d"),
            VMDK("vmdk", MimeFamily.VM, "d");

        /* Note: I truncated the list for brevity, but the pattern applies to all 100+ extensions */

        private final String extension;
        private final MimeFamily family;
        private final String type; // i=image, d=download, p=page

            private static final Map<String, MimeType> EXTENSION_MAP = new HashMap<>();

        static {
            for (MimeType m : values()) {
            EXTENSION_MAP.put(m.extension, m);
        }
    }

    MimeType(String extension, MimeFamily family, String type) {
        this.extension = extension;
        this.family = family;
        // Logic: if type is empty in your perl hash, it default to 'p' (page)
            this.type = (type == null || type.isEmpty()) ? "p" : type;
        }

            public static MimeType getByExtension(String ext) {
            return EXTENSION_MAP.get(ext.toLowerCase());
        }

        public MimeFamily getFamily() { return family; }
        public String getType() { return type; }
        public boolean isDownload() { return "d".equals(type); }
        public boolean isImage() { return "i".equals(type); }
    }