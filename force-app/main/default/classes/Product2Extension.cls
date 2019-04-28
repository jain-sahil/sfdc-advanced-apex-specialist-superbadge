public class Product2Extension {
    
    public List<ProductWrapper> productsToInsert {get; set;}
    
    public Product2Extension(ApexPages.StandardController controller){
        productsToInsert = new List<ProductWrapper>();
        AddRows();
    }
    
    public void AddRows(){
        for (Integer i=0; i<Constants.DEFAULT_ROWS; i++ ) {
            productsToInsert.add( new ProductWrapper() );
        }
    }
    
    public List<ChartHelper.ChartData> GetInventory(){
        return ChartHelper.GetInventory();
    }
    
    public List<SelectOption> GetFamilyOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(Constants.SELECT_ONE, Constants.SELECT_ONE));
        for(PickListEntry eachPicklistValue : Constants.PRODUCT_FAMILY) {
            options.add(new SelectOption(eachPicklistValue.getValue(), eachPicklistValue.getLabel()));
        }
        return options;
    }
    
    public PageReference Save(){
        Savepoint sp = Database.setSavepoint();
        
        List<Product2> products= new List<Product2>();
        List<PricebookEntry> pbes= new List<PricebookEntry>();
        for (ProductWrapper prodwrapper : productsToInsert){
            if(prodwrapper.productRecord != null && prodwrapper.pricebookEntryRecord != null) {
                if(prodwrapper.productRecord.Name != null && prodwrapper.productRecord.Name!='' && prodwrapper.productRecord.Family != null && prodwrapper.productRecord.Family!=''
                   && Constants.SELECT_ONE != prodwrapper.productRecord.Family && prodwrapper.productRecord.Initial_Inventory__c != null 
                   && prodwrapper.pricebookEntryRecord.UnitPrice != null) {
                       System.debug('Enetered');
                       products.add(prodwrapper.productRecord);
                       PricebookEntry pbe = prodwrapper.pricebookEntryRecord;
                       pbe.IsActive = true;
                       pbe.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
                       pbes.add(pbe);
                   }
            }
        }
        if(NULL!= products && products.size()>0){
            insert products;
            System.debug('Enetred in try'+products);
            for (integer i = 0; i < pbes.size(); i++) {
                pbes[i].Product2Id = products[i].Id;
            }
            if(NULL!=pbes && pbes.size()>0){
                insert pbes;
            }
            //If successful clear the list and display an informational message
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,products.size()+' Inserted'));            
        }else{
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Constants.ERROR_MESSAGE));
        }
        productsToInsert.clear();//Do not remove
        AddRows();//Do not remove
        return null;
    }
    
    public class ProductWrapper {
        public Product2 productRecord {get; set;}
        public PriceBookEntry pricebookEntryRecord {get; set;}
        
        public ProductWrapper() {
            productRecord = new Product2(Initial_Inventory__c =0);
            pricebookEntryRecord = new PriceBookEntry(Unitprice=0.0);
        }
    }
}