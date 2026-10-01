package egovframework.com.cmm.util;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * @Class Name : EgovHttpRequestHelper.java
 * @Description : HTTP Request 정보 취득 Helper 클래스
 * @Modification Information
 *
 *    수정일         수정자         수정내용
 *    -------        -------     -------------------
 *    2014.09.11	표준프레임워크		최초생성
* @author Vincent Han
 * @since 2014.09.11
 * @version 3.5
 * @see <pre>
 * web.xml 상에 다음과 같은 Listener 등록 필요
 * &lt;listener&gt;
 *	  &lt;listener-class&gt;org.springframework.web.context.request.RequestContextListener&lt;/listener-class&gt;
 * &lt;/listener&gt;
 * </pre>
 */
public class EgovHttpRequestHelper {
	
	public static boolean isInHttpRequest() {
		// currentRequestAttributes() 는 요청 밖(Quartz 스케줄 스레드 등)에서 JSF(FacesContext) 폴백을
		// 시도하는데, classpath 의 javaee-api(스텁 — javax.faces.LogStrings 리소스 번들 없음) 때문에
		// MissingResourceException 이 IllegalStateException 캐치를 뚫고 새어나와 배치 잡이 죽었다
		// (2026-08-04 사용로그 userLogging 실사고 — faces-api 제거 후 발현).
		// getRequestAttributes() 는 스레드 홀더만 보고 없으면 null 이라 JSF 폴백 자체를 타지 않는다.
		return RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes;
	}
	
	public static HttpServletRequest getCurrentRequest() {
		ServletRequestAttributes sra = (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
		
		return sra.getRequest();
	}
	
	public static String getRequestIp() {
		return getCurrentRequest().getRemoteAddr();
	}
	
	public static String getRequestURI() {
		return getCurrentRequest().getRequestURI();
	}
	
	public static HttpSession getCurrentSession() {
		return getCurrentRequest().getSession();
	}
}
