/**
 * File:        WarehouseSyncSchedule.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 18, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Class to schedule enqueue WarehouseCalloutService
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
public with sharing class WarehouseSyncSchedule implements Schedulable{

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name execute
     * @description interface method to enqueue WarehouseCalloutService
     * @params SchedulableContext
     */
	public void execute(SchedulableContext sc) {
        ID jobId = System.enqueueJob(new WarehouseCalloutService());
    }
}