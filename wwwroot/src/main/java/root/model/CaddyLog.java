package root.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.time.Instant;
import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class CaddyLog {
    public String level;
    public Instant ts;
    public String logger;
    public String msg;
    public Request request;
    public long bytesRead;
    public String userId;
    public double duration;
    public long size;
    public int status;
    public Map<String, List<String>> respHeaders;

    @JsonIgnoreProperties(ignoreUnknown = true)
    @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
    public static class Request {
        public String remoteIp;
        public String remotePort;
        public String clientIp;
        public String proto;
        public String method;
        public String host;
        public String uri;
        public Map<String, List<String>> headers;
        public Tls tls;
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    @JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
    public static class Tls {
        public boolean resumed;
        public int version;
        public int cipherSuite;
        public String proto;
        public String serverName;
    }
}