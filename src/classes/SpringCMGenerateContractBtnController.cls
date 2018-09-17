/**
 * @description Controller class for SpringCMGenerateContractBtnControllerBtn page
 */
public with sharing class SpringCMGenerateContractBtnController extends SpringCMBtnController {

    public SpringCMGenerateContractBtnController(ApexPages.StandardController stdController) {
        super(stdController);
        this.springCMAction = SpringCMBtnController.SPRING_CM_CONTRACT_CREATOR;
    }
}