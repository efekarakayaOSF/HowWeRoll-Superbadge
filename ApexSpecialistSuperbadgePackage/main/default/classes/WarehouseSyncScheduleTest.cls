/**
 * File:        WarehouseSyncScheduleTest.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 19, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Class to test WarehouseSyncSchedule schedule class.
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
@isTest
public with sharing class WarehouseSyncScheduleTest {
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 19, 2021
     * @name testSchedule
     * @description test method to create schedule and compare data
     * @reference https://salesforce.stackexchange.com/a/149718
     */
    @isTest static void testSchedule() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(true, false)); // Single success
        
        List<AsyncApexJob> jobsBefore = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob];
        System.assertEquals(0, jobsBefore.size(), 'Not expecting any asyncjobs');
        
        Test.startTest();
        String jobId = System.schedule('WarehouseSyncScheduleJob', '0 0 0 15 3 ? 2072', new WarehouseSyncSchedule());
        Test.stopTest();
        
        List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClass.Name FROM AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'Expecting one scheduled job');
        System.assertEquals('WarehouseSyncSchedule',jobsScheduled[0].ApexClass.Name, 'Expecting specific scheduled job.');
        
        List<AsyncApexJob> jobsApexQueued = [SELECT Id, ApexClass.Name FROM AsyncApexJob where JobType = 'Queueable'];
        System.assertEquals(1, jobsApexQueued.size(), 'Expecting one apex queued job.');
        System.assertEquals('WarehouseCalloutService', jobsApexQueued[0].ApexClass.Name, 'Expecting specific queued job.');
    }
}