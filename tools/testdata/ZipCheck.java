import java.io.*; import java.util.zip.*;
public class ZipCheck {
  public static void main(String[] a) throws Exception {
    for (String f : a) {
      ZipInputStream zis = new ZipInputStream(new FileInputStream(f));
      ZipEntry e; int total = 0; byte[] buf = new byte[8192];
      while ((e = zis.getNextEntry()) != null) {
        int sz = 0, n;
        while ((n = zis.read(buf)) > 0) sz += n;
        System.out.println(e.getName() + " | " + sz + "b");
        zis.closeEntry(); total++;
      }
      zis.close();
      System.out.println("OK entries=" + total + " <= " + f);
    }
  }
}