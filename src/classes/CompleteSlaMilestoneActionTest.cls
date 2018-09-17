@IsTest
public with sharing class CompleteSlaMilestoneActionTest {
    @IsTest
    public static void milestoneCompletionTest() {
        Account account = new Account(Name = 'TestAcc');
        insert account;

        Case slaCase = new Case(SLA_Assignment_Time__c = System.now(), AccountId = account.Id, RecordTypeId = RecordTypeHelper.getRtIdByDeveloperName('Case', 'Lease_Transaction'));
        insert slaCase;

        CaseMilestone caseMilestone = [
                SELECT Id, CompletionDate
                FROM CaseMilestone
                WHERE CaseId = :slaCase.Id AND MilestoneType.Name = :CompleteSlaMilestoneAction.MILESTONE_NAME AND CompletionDate = NULL
        ];

        System.assertEquals(null, caseMilestone.CompletionDate);

        CompleteSlaMilestoneAction.completeSLAMilestoneAction(new List<Id>{
                slaCase.Id
        });

        caseMilestone = [
                SELECT Id, CompletionDate
                FROM CaseMilestone
                WHERE Id = :caseMilestone.Id
        ];
        System.assertNotEquals(null, caseMilestone.CompletionDate);
    }
}