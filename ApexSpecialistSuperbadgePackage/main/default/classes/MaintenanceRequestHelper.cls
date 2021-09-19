/**
 * File:        MaintenanceRequestHelper.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 17, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Trigger helper class to insert new routines when needed criteria is met.
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
public with sharing class MaintenanceRequestHelper {
    public Map<Id, Case> routines {get; set;}
    public List<Equipment_Maintenance_Item__c> equipments {get; set;}


    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name updateWorkOrders
     * @description driver method to setup required initial data, control new updated maintenance requests one by one to see
     *     if there is one with Type = 'Routine Maintenace' or 'Repair' and also Status = 'Closed', after necessary assignments
     *     insert new routines.
     * @params newList = new updated maintenance requests, newMap = map of new updated maintenance requests
     */
    public void updateWorkOrders(List<Case> newList, Map<Id, Case> newMap) {
        if(!initialSetup(newMap)) return;
        
        for(Case c : newList) {
            if((c.Type != 'Routine Maintenance' && c.Type != 'Repair') || c.Status != 'Closed') {
                continue;
            }

            Case newRoutine = new Case(Status = 'New', Type = 'Routine Maintenance', Origin = c.Origin);
            newRoutine.ParentId = c.Id;
            newRoutine.ProductId = c.productId;
            newRoutine.Date_Reported__c = c.Date_Reported__c;
			newRoutine.Date_Due__c = determineDueDate(c.Id);
            newRoutine.Vehicle__c = c.Vehicle__c;        
      		newRoutine.Subject = 'Routine checkup for Maintenance Request =  ' + c.CaseNumber;
            
            routines.put(c.Id, newRoutine);
        }
        insertRoutinesAndUpdateEquipments();
    }
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name initialSetup
     * @description method to create list of existing equipments (Product2).
     * @params newMap = map of new updated maintenance requests
     * @return true if operation is done, false if failed.
     */
    public Boolean initialSetup(Map<Id, Case> newMap) {
        routines = new Map<Id, Case>();
        try {
            // These fields are necessary.
            equipments = [SELECT Equipment__r.Maintenance_Cycle__c, Maintenance_Request__c 
                		 FROM Equipment_Maintenance_Item__c WHERE Maintenance_Request__c IN :newMap.keySet()];   
            if(equipments.size() == 0) {
                throw new QueryException();
            }
            return true; 
        } catch(QueryException q) {
            System.debug('::: Error! Initial setup of MaintenanceRequest trigger was failed. Detail -> ' + q);
            return false;
        }
    }
    
    
    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name insertRoutinesAndUpdateEquipments
     * @description method to insert new routines and update relevant equipments.
     * @return true if operation is done, false if failed.
     */
    public Boolean insertRoutinesAndUpdateEquipments() {
        // This method does not create new equipments, insted of that, it changes the maintenance_request field
        // of the equipments.
        try {
            insert routines.values();
            
            List<Equipment_Maintenance_Item__c> equipmentsToUpdate = new List<Equipment_Maintenance_Item__c>();
            for(Equipment_Maintenance_Item__c eq : equipments) {
            	Case insertedCase = routines.get(eq.Maintenance_Request__c); // To get ID of the new inserted routines
                if(insertedCase != null) {
                    eq.Maintenance_Request__c = insertedCase.Id;
                	equipmentsToUpdate.add(eq);
                }
      		}   
            update equipmentsToUpdate;
            
            return true;
        } catch(DmlException d) {
            System.debug('::: Error! The insert and update operation was failed. Detail -> ' + d);
            return false;
        }
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 17, 2021
     * @name determineDueDate
     * @description method to determine maintenance request due date according to related equipments
     * @params Id of the maintenance request
     * @return minimum due date according to maintenance cycles
     */
    public Date determineDueDate(Id caseId) {
        Integer minCycle = 0;
        for(Equipment_Maintenance_Item__c eq : equipments) {
            if(eq.Maintenance_Request__c == caseId) {
                Integer cycle = (Integer) eq.Equipment__r.Maintenance_Cycle__c;
                if(minCycle == 0 || cycle < minCycle) {
                    minCycle = cycle;
                }
            }
        }
        Date t = System.today();
        return t.addDays(minCycle);
    }
}