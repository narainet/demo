/*
 * 물리적 저장 경로: /src/main/java/narainet/law/receipt/mapper/LawReceiptMapper.java
 *
 * 법원서류접수(LAW_COURT_RECEIPT) 조회·저장·삭제. §7.11
 */
package narainet.law.receipt.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import narainet.law.receipt.service.LawReceiptVO;

@Mapper
public interface LawReceiptMapper {

	List<LawReceiptVO> selectReceiptList(LawReceiptVO searchVO);

	int selectReceiptCnt(LawReceiptVO searchVO);

	LawReceiptVO selectReceipt(@Param("receiptId") Long receiptId);

	void insertReceipt(LawReceiptVO vo);

	void updateReceipt(LawReceiptVO vo);

	void deleteReceipt(@Param("receiptId") Long receiptId);
}
