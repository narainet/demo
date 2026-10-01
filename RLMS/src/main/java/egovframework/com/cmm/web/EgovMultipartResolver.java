package egovframework.com.cmm.web;

/*
 * Copyright 2001-2006 The Apache Software Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the ";License&quot;);
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS"; BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletContext;

import org.apache.commons.fileupload.FileItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.commons.CommonsMultipartFile;
import org.springframework.web.multipart.commons.CommonsMultipartResolver;

import egovframework.com.cmm.exception.EgovFileExtensionException;
import egovframework.com.cmm.service.EgovProperties;
import egovframework.com.utl.fcc.service.EgovFileUploadUtil;

/**
 * 실행환경의 파일업로드 처리를 위한 기능 클래스
 *
 * @author 공통서비스개발팀 이삼섭
 * @since 2009.06.01
 * @version 1.0
 * @see
 *
 *      <pre>
 * << 개정이력(Modification Information) >>
 *
 *  수정일                수정자             수정내용
 *  ----------   --------    ---------------------------
 *  2009.03.25   이삼섭              최초 생성
 *  2011.06.11   서준식              스프링 3.0 업그레이드 API변경으로인한 수정
 *  2020.10.27   신용호              예외처리 수정
 *  2020.10.29   신용호              허용되지 않는 확장자 업로드 제한 (globals.properties > Globals.fileUpload.Extensions)
 *
 *      </pre>
 */
public class EgovMultipartResolver extends CommonsMultipartResolver {

	private static final Logger LOGGER = LoggerFactory.getLogger(EgovMultipartResolver.class);

	public EgovMultipartResolver() {
	}

	/**
	 * 첨부파일 처리를 위한 multipart resolver를 생성한다.
	 *
	 * @param servletContext
	 */
	public EgovMultipartResolver(ServletContext servletContext) {
		super(servletContext);
	}

	/**
	 * multipart에 대한 parsing을 처리한다.
	 */
	@Override
	protected MultipartParsingResult parseFileItems(List<FileItem> fileItems, String encoding) {

		// 스프링 3.0변경으로 수정한 부분
		MultiValueMap<String, MultipartFile> multipartFiles = new LinkedMultiValueMap<String, MultipartFile>();
		Map<String, String[]> multipartParameters = new HashMap<String, String[]>();
		String whiteListFileUploadExtensions = EgovProperties.getProperty("Globals.fileUpload.Extensions");
		// 브랜드(로고·파비콘) 전용 확장자 화이트리스트 — 지정한 파일 필드로 올라온 것에만 적용한다.
		// SVG 는 스크립트를 품을 수 있어 전역 허용하지 않는다(게시판 첨부 등에서 저장형 XSS 면이 늘어난다).
		// 이 필드를 읽는 컨트롤러는 관리자 전용 브랜드설정 하나뿐이고, 거기서 확장자를 한 번 더 검사한다.
		String brandExtensions = EgovProperties.getProperty("Globals.fileUpload.Extensions.Brand");
		String brandFields = EgovProperties.getProperty("Globals.fileUpload.Fields.Brand");
		Map<String, String> mpParamContentTypes = new HashMap<String, String>();

		// Extract multipart files and multipart parameters.
		for (Iterator<FileItem> it = fileItems.iterator(); it.hasNext();) {
			FileItem fileItem = it.next();

			if (fileItem.isFormField()) {

				String value = null;
				if (encoding != null) {
					try {
						value = fileItem.getString(encoding);
					} catch (UnsupportedEncodingException ex) {
						LOGGER.warn("Could not decode multipart item '{}' with encoding '{}': using platform default",
								fileItem.getFieldName(), encoding);
						value = fileItem.getString();
					}
				} else {
					value = fileItem.getString();
				}
				String[] curParam = multipartParameters.get(fileItem.getFieldName());
				if (curParam == null) {
					// simple form field
					multipartParameters.put(fileItem.getFieldName(), new String[] { value });
				} else {
					// array of simple form fields
					String[] newParam = StringUtils.addStringToArray(curParam, value);
					multipartParameters.put(fileItem.getFieldName(), newParam);
				}

				//contentType 입력
				mpParamContentTypes.put(fileItem.getFieldName(), fileItem.getContentType());
			} else {

				CommonsMultipartFile file = createMultipartFile(fileItem);
				multipartFiles.add(file.getName(), file);

				LOGGER.debug("Found multipart file [{" + file.getName() + "}] of size {" + file.getSize()
						+ "} bytes with original filename [{" + file.getOriginalFilename() + "}], stored {"
						+ file.getStorageDescription() + "}");

				String fileName = file.getOriginalFilename();
				String fileExtension = EgovFileUploadUtil.getFileExtension(fileName);
				LOGGER.debug("Found File Extension = "+fileExtension);

				// 브랜드 파일 필드면 전용 화이트리스트로 교체(미설정이면 전역 목록 그대로)
				String allowedExtensions = whiteListFileUploadExtensions;
				if (isBrandField(file.getName(), brandFields) && brandExtensions != null && !"".equals(brandExtensions)) {
					allowedExtensions = brandExtensions;
					LOGGER.debug("Brand upload field [{}] — using brand extension whitelist.", file.getName());
				}
				if (allowedExtensions == null || "".equals(allowedExtensions)) {
					LOGGER.debug("The file extension whitelist has not been set.");
				} else {
					if (fileName == null || "".equals(fileName)) {
						LOGGER.debug("No file name.");
					} else {
						if ("".equals(fileExtension)) { // 확장자 없는 경우 처리 불가
							throw new EgovFileExtensionException("[No file extension] File extension not allowed.","errors.file.extension.none");
						}
						if ((allowedExtensions+".").contains("."+fileExtension.toLowerCase()+".")) {
							LOGGER.debug("File extension allowed.");
						} else {
							LOGGER.info("["+fileExtension+"] File extension not allowed.{} OK");
							throw new EgovFileExtensionException("["+fileExtension+"] File extension not allowed.","errors.file.extension.deny");
						}
					}
				}

			}
		}

		return new MultipartParsingResult(multipartFiles, multipartParameters, mpParamContentTypes);//2022.01. Method call passes null for non-null parameter 처리
	}

	/**
	 * 브랜드 전용 화이트리스트를 적용할 파일 필드인지 판정한다.
	 * 목록은 Globals.fileUpload.Fields.Brand (쉼표 구분, 예: logoFile,faviconFile).
	 *
	 * @param fieldName  multipart 파일 필드명
	 * @param brandFields 설정된 브랜드 필드 목록
	 * @return 브랜드 필드면 true
	 */
	private boolean isBrandField(String fieldName, String brandFields) {
		if (fieldName == null || brandFields == null || "".equals(brandFields.trim())) {
			return false;
		}
		String[] fields = brandFields.split(",");
		for (int i = 0; i < fields.length; i++) {
			if (fieldName.equals(fields[i].trim())) {
				return true;
			}
		}
		return false;
	}
}
