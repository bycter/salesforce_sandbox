/**
 * @description Controller class for LTCaseGenerateDocumentsBtn page
 */
public with sharing class LTCaseGenerateDocumentsBtnController extends SpringCMBtnController {

    public LTCaseGenerateDocumentsBtnController(ApexPages.StandardController stdController) {
        super(stdController);
        this.springCMAction = SpringCMBtnController.SPRING_CM_DOCUMENT_CREATOR;
    }
}