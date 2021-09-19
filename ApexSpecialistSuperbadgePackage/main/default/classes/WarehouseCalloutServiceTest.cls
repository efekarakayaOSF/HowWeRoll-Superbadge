/**
 * File:        WarehouseCalloutServiceTest.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 18, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Class to test operations of WarehouseCalloutService
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
@IsTest
private class WarehouseCalloutServiceTest {


    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name testCallout
     * @description method to test callout
     */
    @isTest static void testCallout() {
        WarehouseCalloutService service = new WarehouseCalloutService();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(true, false)); // Single success
        HttpResponse res = service.getCallout();
        
        String contentType = res.getHeader('Content-Type');
        String actualValue = res.getBody();
        String expectedBody = '[{"_id":"55d66226726b611100aaf741","replacement":true,"quantity":12,' + 
                         '"maintenanceperiod":365,"lifespan":120,"cost":5000,"sku":"100003"}]';
        
        System.assertEquals(res.getHeader('Content-Type'), 'application/json');
        System.assertEquals(res.getBody(), expectedBody);
        System.assertEquals(res.getStatusCode(), 200);
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name testFailedCallout
     * @description method to test failed callout with response code of 500
     */
    @isTest static void testFailedCallout() {
        WarehouseCalloutService service = new WarehouseCalloutService();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(false, false)); // Single fail

        Test.startTest();
        HttpResponse res = service.getCallout();
        Test.stopTest();
        
        System.assertEquals(res.getStatusCode(), 500, 'Test must have been failed.');
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name queueableTest
     * @description method to test if job is queued
     */
    @isTest static void queueableTest() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(true, true)); // Multiple success
        Product2 equipment = new Product2(Name = 'testName', Replacement_Part__c = true, 
                                          Warehouse_SKU__c = '55d66226726b611100aaf741', Maintenance_Cycle__c = 1);
        Test.startTest();
        insert equipment;
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE ID = :jobId];
        System.assertEquals(job.Status, 'Queued' , 'Job status must have been \'Queued\'');
        Test.stopTest();
        
        Product2 upEquipment = [SELECT Maintenance_Cycle__c FROM Product2 WHERE Warehouse_SKU__c = '55d66226726b611100aaf741' LIMIT 1][0];
        Integer equipmentCount = [SELECT Count() FROM Product2];
        job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];

        System.assertEquals(job.Status, 'Completed', 'Job must have been worked.');
        System.assertEquals(equipment.Maintenance_Cycle__c, 1, 'Upsert operation could not worked.');
        System.assertEquals(equipmentCount, 2, 'Total equipment size must have been equal to 2.');
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name failedSyncUpdate
     * @description method to test failed update equipments
     */
    @isTest static void failedSyncUpdate() {
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock(true, false)); // Single success
        WarehouseCalloutService service = new WarehouseCalloutService();    
        
        Test.startTest();
        HttpResponse resp = service.getCallout();
        Boolean result = service.deserializeAndSyncUpdate(resp.getBody());
        Test.stopTest();
        
        System.assertEquals(result, false, 'Deserialize response and sync update process must have been failed.');
    }
}