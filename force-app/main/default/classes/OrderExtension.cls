/**
* @name OrderExtension
* @description This class is provided for you to facilitate the Super Badge
**/
public class OrderExtension {
    
    public Order orderRecord {get; set;}
    public List<OrderItem> orderItemList {get; set;}
    public String selectedFamily {get; set;}
    public List<chartHelper.chartData> pieData {get; set;}
    public Decimal total {get; set;}
    
    public Map<Id,OrderItem> orderItemMap;
    ApexPages.StandardSetController standardSetController;
    
    public OrderExtension(ApexPages.StandardController standardController){
        orderRecord = (Order)standardController.getRecord();
        orderItemMap = new Map<Id, OrderItem>();
        if( orderRecord.Id != null ) {
            orderRecord = queryOrderRecord(orderRecord.Id);
        }
        
        refreshStandardSetController();
        total = 0;
        
        for (OrderItem oi : orderRecord.OrderItems) {
            orderItemMap.put(oi.Product2Id, oi);
            if(oi.Quantity > 0) {
                if(null == pieData) {
                    pieData = new List<ChartHelper.ChartData>();
                }
                pieData.add(new chartHelper.ChartData(oi.Product2.Name, oi.Quantity * oi.UnitPrice));
                total += oi.UnitPrice * oi.Quantity;
            }
        }
        loadData();
    }
    
    void refreshStandardSetController(){
        String query = 'SELECT Name, Product2.Family, Product2.Name, Product2Id, UnitPrice, Product2.Quantity_Remaining__c FROM PricebookEntry WHERE IsActive = TRUE';
        
        if(selectedFamily != null && selectedFamily != Constants.SELECT_ONE) {
            query += ' AND Product2.Family = \'' + selectedFamily + '\'';
        }
        query += ' ORDER BY Name';
        
        standardSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        standardSetController.setPageSize(Constants.DEFAULT_ROWS);
    }
    
    void loadData(){
        orderItemList = new List<OrderItem>();
        for (SObject obj : standardSetController.getRecords()) {
            PricebookEntry pbe = (PricebookEntry)obj;
            
            if(orderItemMap.containsKey(pbe.Product2Id)) {
                orderItemList.add(orderItemMap.get(pbe.Product2Id));
            } else{
                OrderItem ot = new OrderItem(
                    PricebookEntryId = pbe.Id,
                    Product2Id = pbe.Product2Id,
                    UnitPrice = pbe.UnitPrice,
                    Quantity = 0,
                    Product2 = pbe.Product2
                );
                orderItemList.add(ot);
                orderItemMap.put(pbe.Product2Id, ot);
            }
        }
    }
    
    
    /**
* @name OnFieldChange
* @description
**/
    public void OnFieldChange(){
        for (OrderItem oi : orderItemList) {
            orderItemMap.put(oi.Product2Id, oi);
        }
        
        pieData = null;
        total = 0;
        for (OrderItem oi : orderItemMap.values()) {
            if(oi.Quantity > 0) {
                if(null == pieData) {
                    pieData = new List<chartHelper.ChartData>();
                }
                pieData.add(new chartHelper.ChartData(oi.Product2.Name, oi.Quantity * oi.UnitPrice));
                //      and populate total
                total += oi.UnitPrice * oi.Quantity;
            }
            
        }
        
    }
    
    /**
* @name SelectFamily
* @description
**/
    public void SelectFamily(){
        refreshStandardSetController();
        loadData();
    }
    
    /**
* @name Save
* @description
**/
    public void Save(){
        
        System.Savepoint sp = Database.setSavepoint();
        
        try {
            if(orderRecord.Pricebook2Id == null) {
                orderRecord.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            }
            upsert orderRecord;
            
            List<OrderItem> orderItemsToUpsert = new List<OrderItem>();
            List<OrderItem> orderItemsToDelete = new List<OrderItem>();
            
            for (OrderItem oi : orderItemMap.values()) {
                if(oi.Quantity > 0) {
                    if(oi.OrderId == null) {
                        oi.OrderId = orderRecord.Id;
                    }
                    orderItemsToUpsert.add(oi);
                } else if(oi.Id != null) {
                    orderItemsToDelete.add(new OrderItem(id=oi.Id));
                    oi.Id = null;
                }
            }
            
            upsert orderItemsToUpsert;
            delete orderItemsToDelete;
            
        } catch (Exception e){
            Database.rollback(sp);
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,Constants.ERROR_MESSAGE));
        }
    }
    
    
    /**
* @name First
* @description
**/
    public void First(){
        standardSetController.first();
        loadData();
    }
    
    
    /**
* @name Next
* @description
**/
    public void Next(){
        standardSetController.next();
        loadData();
    }
    
    
    /**
* @name Previous
* @description
**/
    public void Previous(){
        standardSetController.previous();
        loadData();
    }
    
    /**
* @name Last
* @description
**/
    public void Last(){
        standardSetController.last();
        loadData();
    }
    
    /**
* @name GetHasPrevious
* @description
**/
    public Boolean GetHasPrevious(){
        return standardSetController.getHasPrevious();
    }
    
    /**
* @name GetHasNext
* @description
**/
    public Boolean GetHasNext(){
        return standardSetController.getHasNext();
    }
    
    /**
* @name GetTotalPages
* @description
**/
    public Integer GetTotalPages(){
        return (Integer)Math.ceil(standardSetController.getResultSize() / (Decimal)Constants.DEFAULT_ROWS);
    }
    
    /**
* @name GetPageNumber
* @description
**/
    public Integer GetPageNumber(){
        return standardSetController.getPageNumber();
    }
    
    /**
* @name GetFamilyOptions
* @description
**/
    
    public List<SelectOption> GetFamilyOptions (){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(Constants.SELECT_ONE, Constants.SELECT_ONE));
        for(Schema.Picklistentry ple : Constants.PRODUCT_FAMILY) {
            options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        return options;
    }
    
    /**
* @name QueryOrderRecord
* @description
**/
    public static Order QueryOrderRecord(Id orderId){
        return [SELECT Id, AccountId, EffectiveDate, Name, Status, Pricebook2Id,(SELECT Id, OrderId, Quantity, UnitPrice, PricebookEntryId, Product2Id, Product2.Name, Product2.Family, Product2.Quantity_Remaining__c FROM OrderItems) FROM Order WHERE Id = : orderId];
    }
    
}