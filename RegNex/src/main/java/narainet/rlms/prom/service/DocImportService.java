/*
 * 물리적 저장 경로: /src/main/java/narainet/rlms/prom/service/DocImportService.java
 *
 * 규정 편집 IDE - "문서에서 가져오기"
 *   Word(.docx) / 한컬오피스(.hwpx) 문서에서 평문 텍스트를 추출하여
 *   중앙 "버전관리용조문편집" textarea 에 주입 → 사용자가 조문(장/조/항/호) 검토 후 저장.
 *
 *   추출만 담당 (DB 미저장). 원본 파일 보존/다운로드는 별도 흐름.
 *
 *   지원 포맷 (POI 미사용 — poi-ooxml↔xmlbeans 충돌로 순수 ZIP+SAX):
 *     .docx  →  ZIP + word/document.xml(WordprocessingML) SAX 파싱 (순수 자바)
 *     .hwpx  →  ZIP + Contents/section*.xml(OWPML) SAX 파싱 (순수 자바)
 *     .hwp   →  미지원 (.hwpx 권장)
 */
package narainet.rlms.prom.service;

public interface DocImportService {

    /**
     * 문서 평문 추출 — 규정 조문 가져오기용 (법제처 보일러플레이트/머리말 컷 등 규정-특화 정규화 포함).
     * @param fileName  원본 파일명 (확장자로 포맷 판별)
     * @param bytes     파일 바이트
     * @return 조문-친화 평문 (각 문단 = 한 줄)
     * @throws Exception 미지원 포맷 / 파싱 오류
     */
    String extractPlainText(String fileName, byte[] bytes) throws Exception;

    /**
     * 일반 문서 평문 추출 — 관련자료 WORD 자체변환용.
     * extractPlainText 와 달리 규정-특화 정규화를 하지 않고, 원문 평문을 가볍게만
     * 정돈(CR 제거 / 줄끝 공백 trim / 3줄↑ 연속 빈줄 → 1줄)해 그대로 반환한다.
     * @return 추출 평문. 지원하지 않는 포맷(.doc/.hwp/.pdf/.xls 등)이면 null (예외를 던지지 않음).
     * @throws Exception 지원 포맷(.docx/.hwpx)인데 손상되어 파싱 실패한 경우
     */
    String extractRawText(String fileName, byte[] bytes) throws Exception;
}
