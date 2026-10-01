/*
 * 물리적 저장 경로: /src/main/java/egovframework/com/uss/umt/service/impl/EgovMyAccountServiceImpl.java
 */
package egovframework.com.uss.umt.service.impl;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.springframework.stereotype.Service;

import egovframework.com.uss.umt.mapper.EgovMyAccountMapper;
import egovframework.com.uss.umt.service.LoginHistVO;
import egovframework.com.uss.umt.service.EgovMyAccountService;

@Service("egovMyAccountService")
public class EgovMyAccountServiceImpl extends EgovAbstractServiceImpl implements EgovMyAccountService {

	@Resource(name = "egovMyAccountMapper")
	private EgovMyAccountMapper myAccountMapper;

	@Override
	public Map<String, Object> selectMyLoginHistory(String uniqId, LoginHistVO vo) {
		List<LoginHistVO> list = myAccountMapper.selectMyLoginLogList(uniqId, vo);
		int cnt = myAccountMapper.selectMyLoginLogCnt(uniqId, vo);
		Map<String, Object> map = new HashMap<>();
		map.put("resultList", list);
		map.put("resultCnt", Integer.toString(cnt));
		return map;
	}

	@Override
	public Map<String, Object> selectMyProfile(String userSe, String uniqId) {
		return "USR".equals(userSe)
				? myAccountMapper.selectMyProfileUsr(uniqId)
				: myAccountMapper.selectMyProfileGnr(uniqId);
	}

	@Override
	public void updateMyProfile(String userSe, String uniqId, String email, String mbtlnum) {
		if ("USR".equals(userSe)) {
			myAccountMapper.updateMyProfileUsr(uniqId, email, mbtlnum);
		} else {
			myAccountMapper.updateMyProfileGnr(uniqId, email, mbtlnum);
		}
	}
}
