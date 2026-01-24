package root.util;

import java.net.InetAddress;
import java.nio.ByteBuffer;

public class Support {
    public static int ipToInterface(InetAddress ip) {
        return ByteBuffer.wrap(ip.getAddress()).getInt();
    }
}
