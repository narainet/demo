import egovframework.com.utl.sim.service.EgovFileScrty;

public class EncPw {
    public static void main(String[] args) throws Exception {
        // args: <plainPassword> <loginId(salt)>
        System.out.println(EgovFileScrty.encryptPassword(args[0], args[1]));
    }
}
