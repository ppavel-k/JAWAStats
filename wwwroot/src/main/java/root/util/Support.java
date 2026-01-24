package root.util;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.nio.ByteBuffer;

public class Support {

    public static int ipToInterface(InetAddress ip) {
        return ByteBuffer.wrap(ip.getAddress()).getInt();
    }

    public static int ipToInterface(String ip) {
        try {
            InetAddress inetAddress = InetAddress.getByName(ip);
            return ByteBuffer.wrap(inetAddress.getAddress()).getInt();
        } catch (UnknownHostException e) {
            return -1;
        }
    }

    public static InetAddress interfaceToIp(int ipAsInt) throws Exception {
        byte[] bytes = ByteBuffer.allocate(4).putInt(ipAsInt).array();
        return InetAddress.getByAddress(bytes);
    }

}
