import java.util.HashMap;
import java.util.Map;

public enum HttpCode {
    // 1xx Informational
        HTTP_100("100", "Continue"),
        HTTP_101("101", "Switching Protocols"),
        HTTP_102("102", "Processing (WebDAV)"),
        HTTP_103("103", "Early Hints / Checkpoint"),

        // 2xx Success
        CAT_2XX("2xx", "[Miscellaneous successes]"),
        HTTP_200("200", "OK"),
        HTTP_201("201", "Created"),
        HTTP_202("202", "Accepted"),
        HTTP_203("203", "Non-authoritative Information"),
        HTTP_204("204", "No Content"),
        HTTP_205("205", "Reset Content"),
        HTTP_206("206", "Partial Content"),
        HTTP_207("207", "Multi-Status (WebDAV)"),
        HTTP_208("208", "Already Reported (WebDAV)"),
        HTTP_218("218", "This is fine (Apache Web Server)"),
        HTTP_226("226", "IM Used"),

        // 3xx Redirection
        CAT_3XX("3xx", "[Miscellaneous redirections]"),
        HTTP_300("300", "Multiple Choices"),
        HTTP_301("301", "Moved Permanently (redirect)"),
        HTTP_302("302", "Found (Previously 'Moved temporarily')"),
        HTTP_303("303", "See Other"),
        HTTP_304("304", "Not Modified (since last retrieval)"),
        HTTP_305("305", "Use Proxy"),
        HTTP_306("306", "Switch Proxy"),
        HTTP_307("307", "Temporary Redirect"),
        HTTP_308("308", "Permanent Redirect"),

        // 4xx Client Errors
        CAT_4XX("4xx", "[Miscellaneous client/user errors]"),
        HTTP_400("400", "Bad Request"),
        HTTP_401("401", "Unauthorized"),
        HTTP_402("402", "Payment Required"),
        HTTP_403("403", "Forbidden"),
        HTTP_404("404", "Not Found (hits on favicon excluded)"),
        HTTP_405("405", "Method Not Allowed"),
        HTTP_406("406", "Not Acceptable"),
        HTTP_407("407", "Proxy Authentication Required"),
        HTTP_408("408", "Request Timeout"),
        HTTP_409("409", "Conflict"),
        HTTP_410("410", "Gone"),
        HTTP_411("411", "Length Required"),
        HTTP_412("412", "Precondition Failed"),
        HTTP_413("413", "Payload Too Large"),
        HTTP_414("414", "URI Too Long"),
        HTTP_415("415", "Unsupported Media Type"),
        HTTP_416("416", "Range Not Satisfiable"),
        HTTP_417("417", "Expectation Failed"),
        HTTP_418("418", "I am a teapot"),
        HTTP_419("419", "Page Expired (Laravel Framework)"),
        HTTP_420("420", "Method Failure (Spring Framework) / Enhance Your Calm (Twitter)"),
        HTTP_421("421", "Misdirected Request"),
        HTTP_422("422", "Unprocessable Entity (WebDAV)"),
        HTTP_423("423", "Locked (WebDAV)"),
        HTTP_424("424", "Failed Dependency (WebDAV)"),
        HTTP_425("425", "Too Early"),
        HTTP_426("426", "Upgrade Required"),
        HTTP_428("428", "Precondition Required"),
        HTTP_429("429", "Too Many Requests"),
        HTTP_430("430", "Request Header Fields Too Large (Shopify)"),
        HTTP_431("431", "Request Header Fields Too Large"),
        HTTP_440("440", "Login Time-out (IIS)"),
        HTTP_444("444", "No Response (nginx)"),
        HTTP_449("449", "Retry With (IIS)"),
        HTTP_450("450", "Blocked by Windows Parental Controls (Microsoft)"),
        HTTP_451("451", "Unavailable For Legal Reasons / Redirect (IIS)"),
        HTTP_460("460", "Client closed connection before idle timeout (AWS ELB)"),
        HTTP_463("463", "X-Forwarded-For header > 30 IPs (AWS ELB)"),
        HTTP_494("494", "Request header too large (nginx)"),
        HTTP_495("495", "SSL Certificate Error (nginx)"),
        HTTP_496("496", "SSL Certificate Required (nginx)"),
        HTTP_497("497", "HTTP Request Sent to HTTPS Port (nginx)"),
        HTTP_498("498", "Invalid Token (Esri)"),
        HTTP_499("499", "Client Closed Request (nginx) / Token Required (Esri)"),

        // 5xx Server Errors
        CAT_5XX("5xx", "[Miscellaneous server errors]"),
        HTTP_500("500", "Internal Server Error"),
        HTTP_501("501", "Not Implemented"),
        HTTP_502("502", "Bad Gateway"),
        HTTP_503("503", "Service Unavailable"),
        HTTP_504("504", "Gateway Timeout"),
        HTTP_505("505", "HTTP Version Not Supported"),
        HTTP_506("506", "Variant Also Negotiates"),
        HTTP_507("507", "Insufficient Storage (WebDAV)"),
        HTTP_508("508", "Loop Detected (WebDAV)"),
        HTTP_509("509", "Bandwidth Limit Exceeded (Apache/cPanel)"),
        HTTP_510("510", "Not Extended"),
        HTTP_511("511", "Network Authentication Required"),
        HTTP_520("520", "Unknown Error (Cloudflare)"),
        HTTP_521("521", "Web Server Is Down (Cloudflare)"),
        HTTP_522("522", "Connection Timed Out (Cloudflare)"),
        HTTP_523("523", "Origin Is Unreachable (Cloudflare)"),
        HTTP_524("524", "A Timeout Occurred (Cloudflare)"),
        HTTP_525("525", "SSL Handshake Failed (Cloudflare)"),
        HTTP_526("526", "Invalid SSL Certificate (Cloudflare)"),
        HTTP_527("527", "Railgun Error (Cloudflare)"),
        HTTP_530("530", "Origin DNS Error (Cloudflare) / Site is frozen (Pantheon)"),
        HTTP_598("598", "Network read timeout error (Informal)"),

        UNKNOWN("xxx", "[Unknown]");

    private final String code;
    private final String description;
    private static final Map<String, HttpCode> BY_CODE = new HashMap<>();

    static {
        for (HttpCode hc : values()) {
            BY_CODE.put(hc.code, hc);
        }
    }

        HttpCode(String code, String description) {
        this.code = code;
        this.description = description;
    }

    public String getCode() { return code; }
    public String getDescription() { return description; }

    /**
     * Finds the description for a specific code.
     * If code not found, returns the category (e.g. 4xx) or UNKNOWN.
     */
    public static HttpCode lookup(String code) {
        if (BY_CODE.containsKey(code)) {
            return BY_CODE.get(code);
        }
        // Handle generic categories if the specific code isn't listed
        if (code != null && code.length() == 3) {
            String category = code.charAt(0) + "xx";
            return BY_CODE.getOrDefault(category, UNKNOWN);
        }
        return UNKNOWN;
    }
}