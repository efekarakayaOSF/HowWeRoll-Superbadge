/**
 * File:        WarehouseCalloutServiceMock.cls
 * Project:     Apex Specialist Superbadge
 * Date:        September 18, 2021
 * Created By:  Efe Kaan Karakaya
 * *************************************************************************
 * Description:  Mock class to retrieve fake response.
 * *************************************************************************
 * History:
 * Date:                Modified By:             Description:
 */
@isTest
public class WarehouseCalloutServiceMock implements HttpCalloutMock {
    private Boolean success; // Used for positive/negative tests.
    private Boolean multiple; // Used for single/bulk tests.


    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name WarehouseCalloutServiceMock
     * @description constructor to set success and multiple values.
     * @params isSuccess? , isMultiple?
     */
    public WarehouseCalloutServiceMock(Boolean isSuccess, Boolean isMultiple) {
        success = isSuccess;
        multiple = isMultiple;
    }
    

    /**
     * @author Efe Kaan Karakaya
     * @date  September 18, 2021
     * @name respond
     * @description interface method to built fake response
     * @params default http request
     * @return fake response
     */
    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        
        if(multiple) {
            response.setBody('[{"_id":"55d66226726b611100aaf741","replacement":true,"quantity":12,"name":' + 
                         '"testName","maintenanceperiod":365,"lifespan":120,"cost":5000,"sku":"100003"},' +
                         '{"_id":"55d66226726b611100aaf742","replacement":true,"quantity":12,"name":' + 
                         '"newEquipment","maintenanceperiod":365,"lifespan":120,"cost":5000,"sku":"100004"}]');
        } else {
            // This response does not contain required 'Name' field.
            response.setBody('[{"_id":"55d66226726b611100aaf741","replacement":true,"quantity":12,' + 
                         '"maintenanceperiod":365,"lifespan":120,"cost":5000,"sku":"100003"}]');
        }

        if(success) {
            response.setStatusCode(200);
        } else {
            response.setStatusCode(500);
        }
        
        return response;
    }
}