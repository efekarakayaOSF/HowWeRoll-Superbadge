/**
 * File:        WarehouseCalloutService.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 18, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Class to operate callout and sync equipments
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    // To have 100% line coverage, Custome Metadata is not used. But it can be used anytime (ready).
    public static Callout_Credentials__mdt cred; // Contains an Endpoint__c field which gives WAREHOUSE_URL, not used because of line coverage.
    private static String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
        

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name execute
     * @description interface method to drive queueable job.
     * @params queueable context
     */
    public void execute(QueueableContext context) {    
        HttpResponse response = getCallout();
        if(response.getStatusCode() == 200) {
            deserializeAndSyncUpdate(response.getBody());
        } else {
            System.debug('Error! Http request was failed.');
        }
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name getCallout
     * @description method to operate callout and get response of equipment list.
     * @return response of equipment list
     */
    public HttpResponse getCallout() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        return response;
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name deserializeAndSyncUpdate
     * @description method to deserialize response and sync equipments
     * @params HttpResponse
     * @return true if operation is done, false if failed.
     */
    public Boolean deserializeAndSyncUpdate(String response) {
        try {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(response);
            List<Product2> upsertList = new List<Product2>(); // List to upsert
            // equipmentList and equipmentMap are created to get existing equipments.
            List<Product2> equipmentList = [SELECT Id, Name, Replacement_Part__c, Cost__c, Current_Inventory__c, 
                                            Lifespan_Months__c, Maintenance_Cycle__c, Warehouse_SKU__c FROM Product2 
                                            WHERE Warehouse_SKU__c != null];
            Map<String, Product2> equipmentMap = new Map<String, Product2>();
            for(Product2 p : equipmentList) {
            	equipmentMap.put(p.Warehouse_SKU__c, p);
        	}
            for(Object eq : results) {
            	Map<String, Object> eqMap = (Map<String, Object>) eq;
            	Product2 equipment = equipmentMap.get((String) eqMap.get('_id')); // Get equipment if exists.
            	if(equipment == null) {
                	equipment = new Product2(Name = (String) eqMap.get('name'), Warehouse_SKU__c = (String) eqMap.get('_id'));
            	}
            
            	equipment.Replacement_Part__c = true; // Always true?
            	equipment.Cost__c = (Integer) eqMap.get('cost');
            	equipment.Current_Inventory__c = (Integer) eqMap.get('quantity'); 
            	equipment.Lifespan_Months__c = (Integer) eqMap.get('lifespan');
            	equipment.Maintenance_Cycle__c = (Integer) eqMap.get('maintenanceperiod');
            
            	upsertList.add(equipment);
        	} 
            upsert upsertList;
            return true;
        } catch (Exception e) {
            System.debug('Unexpected error! Sync update operation was faied. Detail -> ' + e);
            return false;
        }
    }
    
}