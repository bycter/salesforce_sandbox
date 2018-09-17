trigger AccountTrigger on Account (after insert, before delete ) {
    new AccountTriggerHandler().run();
}