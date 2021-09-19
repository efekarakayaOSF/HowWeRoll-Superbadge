/**
 * File:        MaintenanceRequest.trigger
 * Project:     Apex Specialist Superbadge
 * Date:        September 17, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Trigger class to insert new routines when needed criteria is met.
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
trigger MaintenanceRequest on Case (before update) {
    MaintenanceRequestHelper helper = new MaintenanceRequestHelper();
    if(Trigger.isBefore) {
        helper.updateWorkOrders(Trigger.New, Trigger.NewMap);
    }
    
}