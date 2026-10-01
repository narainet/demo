/*
 * 물리적 저장 경로: /src/main/java/narainet/law/receipt/service/LawReceiptService.java
 */
package narainet.law.receipt.service;

import java.util.List;
import java.util.Map;

import org.springframework.web.multipart.MultipartFile;

public interface LawReceiptService {

	Map<String, Object> getList(LawReceiptVO searchVO) throws Exception;

	LawReceiptVO getReceipt(Long receiptId) throws Exception;

	Long save(LawReceiptVO vo, List<MultipartFile> files, String userId) throws Exception;

	void delete(Long receiptId) throws Exception;
}
