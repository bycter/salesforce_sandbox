public class CompleteSlaMilestoneAction {
    public static final String MILESTONE_NAME = '48 Lease Transaction SLA';

    @InvocableMethod
    public static void completeSLAMilestoneAction(List<Id> caseIds) {
        List<CaseMilestone> milestones = [
                SELECT Id, CompletionDate
                FROM CaseMilestone
                WHERE CaseId IN :caseIds AND MilestoneType.Name = :MILESTONE_NAME AND CompletionDate = NULL
        ];

        for (CaseMilestone milestone : milestones) {
            milestone.CompletionDate = System.now();
        }
        update milestones;
    }
}