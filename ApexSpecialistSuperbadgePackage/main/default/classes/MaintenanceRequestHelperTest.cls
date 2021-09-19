/**
 * File:        MaintenanceRequestHelperTest.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 17, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Class to test operations of the MaintenanceRequestHelper
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
@isTest
public with sharing class MaintenanceRequestHelperTest {


    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name makeData
     * @description test setup method to create initial data
     */
    @TestSetup static void makeData(){
        Vehicle__c vehicle = new Vehicle__c(Name = 'VehicleTest0');
        insert vehicle;
		
        List<Product2> equipments = new List<Product2>();
        equipments.add(new Product2(Name = 'EquipmentTest0', Maintenance_Cycle__c = 15, Replacement_Part__c = true));
        equipments.add(new Product2(Name = 'EquipmentTest1', Maintenance_Cycle__c = 10, Replacement_Part__c = true));
        equipments.add(new Product2(Name = 'EquipmentTest2', Maintenance_Cycle__c = 20, Replacement_Part__c = true));
        insert equipments;

        List<Case> maintenanceRequests = new List<Case>();
        for(Integer i = 0; i < 150; i++){
            Case newMR;
            if(i < 50) {
                newMR = new Case(Status = 'New', Type = 'Routine Maintenance', Origin = 'Phone');
            } else if(i < 100) {
                newMR = new Case(Status = 'New', Type = 'Repair', Origin = 'Phone');
            } else {
                newMR = new Case(Status = 'New', Type = 'Other', Origin = 'Phone');
            }
            maintenanceRequests.add(newMR);
        }
 
        insert maintenanceRequests;

		List<Equipment_Maintenance_Item__c> items = new List<Equipment_Maintenance_Item__c>();
        for(Case req : maintenanceRequests) {
            for(Product2 p : equipments) {
                Equipment_Maintenance_Item__c item = new Equipment_Maintenance_Item__c(Maintenance_Request__c = req.Id, 
                                                                                        Equipment__c = p.Id);
                items.add(item);
            }
        }
        insert items;
    }
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name singleUpdateTest
     * @description method to test single successful new routine creating.
     */
    @isTest static void singleUpdateTest() {
        Case c = [SELECT Vehicle__c, Origin, Date_Reported__c, Status, Type, 
                  (SELECT Equipment__c FROM Equipment_Maintenance_Items__r) 
                  FROM Case WHERE Type = 'Routine Maintenance' LIMIT 1][0];
        c.Status = 'Closed';
        update c;
        
        // Get new created routine request according to ParentId.
        Case newRoutine = [SELECT Vehicle__c, Origin, Date_Due__c, Date_Reported__c, Status, Type, 
                           (SELECT Equipment__c FROM Equipment_Maintenance_Items__r) 
                           FROM Case WHERE ParentId = :c.Id LIMIT 1][0];
        Date expectedDate = System.today();
        expectedDate = expectedDate.addDays(10);
        
        Integer prevEqSize = c.Equipment_Maintenance_Items__r.size();
        Integer newEqSize = newRoutine.Equipment_Maintenance_Items__r.size();
        
        System.assertEquals(c.Vehicle__c, newRoutine.Vehicle__c, 'Vehicles must be same.');
        System.assertEquals(c.Origin, newRoutine.Origin, 'Origins must be same.');
        System.assertEquals(expectedDate, newRoutine.Date_Due__c, 'The calculation of due date was wrong.');
        System.assertEquals(c.Date_Reported__c, newRoutine.Date_Reported__c, 'Date reported values must be same.');
        System.assertEquals('New', newRoutine.Status, 'Status must be \'New\'');
        System.assertEquals(c.Type, newRoutine.Type, 'Types must be same.');
        System.assertEquals(prevEqSize, newEqSize, 'Equipments could not be matched.');
    }
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name bulkUpdateTest
     * @description method to test multiple successful new routines creating.
     */
    @isTest static void bulkUpdateTest() {
        Integer prevCount = [SELECT Count() FROM Case]; 
        List<Case> requests = [SELECT Status FROM Case WHERE Type = 'Repair'];
        Case anotherReq = [SELECT Status FROM Case WHERE Type = 'Other' LIMIT 1][0];
        requests.add(anotherReq); // This maintenance request won't be processed.
        
        for(Case c : requests) {
            c.Status = 'Closed';
        }
        update requests;

        Integer newCount = [SELECT Count() FROM Case];
        Integer expected = newCount - prevCount;
        
        System.assertEquals(expected, requests.size() -1 , 'New requests could not created.');
    }
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name initialSetupTest
     * @description method to test initial setup operation
     */
    @isTest static void initialSetupTest() {
        MaintenanceRequestHelper helper = new MaintenanceRequestHelper();

        Case req = new Case(Status = 'New', Type = 'Routine Maintenance', Origin = 'Phone');
        insert req;
 
		Map<Id, Case> tmpMap = new Map<Id, Case>();
        tmpMap.put(req.Id, req);
        
        // Since there is no Equipment_Maintenance_Item__c object related with Case 'req',
        // initialSetup function must be failed.
        Boolean result = helper.initialSetup(tmpMap);
        System.assertEquals(false, result, 'Initial Setup must have been failed.');
    }
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name insertRoutinesAndUpdateEquipmentsTest
     * @description method to test insert new routine request and update related equipments operation.
     */
    @isTest static void insertRoutinesAndUpdateEquipmentsTest() {
        MaintenanceRequestHelper helper = new MaintenanceRequestHelper();
        Case req = new Case(Status = 'New', Type = 'Routine Maintenance', Origin = 'Phone');
        insert req;
 
		Map<Id, Case> tmpMap = new Map<Id, Case>();
        tmpMap.put(req.Id, req);
        helper.routines = tmpMap;
        
        Boolean result = helper.insertRoutinesAndUpdateEquipments();
        System.assertEquals(false, result, 'Insert routines operation must have been failed.');     
    }
}