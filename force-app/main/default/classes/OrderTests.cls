@isTest
private class OrderTests {
    
    @testSetup static void SetupTestData(){
        TestDataFactory.InsertTestData(1);
    }
    
    @isTest private static void OrderUpdate_UnitTest(){
        Test.startTest();
        Order o = [SELECT Id, Status FROM Order LIMIT 1];
        Product2 p = [SELECT Id, Family, Name, Quantity_Ordered__c, Quantity_Remaining__c FROM Product2 LIMIT 1];
        
        o.status = constants.ACTIVATED_ORDER_STATUS;
        Update o;
        Product2 updatedp = [SELECT Id, Family, Name, Quantity_Ordered__c, Quantity_Remaining__c FROM Product2 LIMIT 1];
        
        TestDataFactory.VerifyQuantityOrdered(p, updatedp, constants.DEFAULT_ROWS);
        Test.stopTest();
    }
    
    @isTest private static void OrderExtension_UnitTest(){
        PageReference pageRef = Page.OrderEdit;
        Test.setCurrentPage(pageRef);
        Order o = [SELECT Id, Status FROM Order LIMIT 1];
        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(o);
        OrderExtension ext = new OrderExtension(stdcontroller);
        System.assertEquals(1, ext.orderItemList.size());
        ext.OnFieldChange();
        ext.SelectFamily();
        ext.Save();
        ext.First();
        ext.Next();
        ext.Previous();
        ext.Last();
        ext.GetHasPrevious();
        ext.GetHasNext();
        ext.GetTotalPages();
        ext.GetPageNumber();
        List<SelectOption> options = ext.GetFamilyOptions();
    }
}