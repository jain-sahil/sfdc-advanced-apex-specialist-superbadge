public class Product2Helper {

  /**
   * @name COLLABORATION_GROUP
   * @description List of CollaborationGroup used in both business and test logic
   **/
  static List<CollaborationGroup> COLLABORATION_GROUP = [SELECT Id FROM CollaborationGroup WHERE Name = :Constants.INVENTORY_ANNOUNCEMENTS OR Name = :('TEST'+Constants.INVENTORY_ANNOUNCEMENTS)LIMIT 1];

  /**
   * @name afterUpdate
   * @description called by product2 Trigger on After Update
   * @param List<Product2> newList
   * @param List<Product2> oldList
   **/
  public static void afterUpdate(List<Product2> newList){
    //ToDo: Declare a List of Product2 records named needsAnnouncement
    List<Product2> needsAnnouncement = new List<Product2>();

    //ToDo: Declare a Map of Strings to Inventory_Setting__mdt records
    Map<String, Decimal> invSettingMap = new Map<String, Decimal>();

    //ToDo: Loop through a query of Inventory_Setting__mdt records and populate the Map with Name as the key
    List<Inventory_Setting__mdt> invSettings = [SELECT Id, DeveloperName, Low_Quantity_Alert__c FROM Inventory_Setting__mdt];

    for(Inventory_Setting__mdt e : invSettings) {
      invSettingMap.put(e.DeveloperName, e.Low_Quantity_Alert__c);
    }

    for(Product2 c : newList) {
      if(invSettingMap.containsKey(c.Family) && c.Quantity_Remaining__c < invSettingMap.get(c.Family)) {
        needsAnnouncement.add(c);
      }
    }

    PostAlerts(needsAnnouncement);
  }

  /**
   * @name postAlerts
   * @description called by product2 Trigger on After Update
   * @param List<Product2> productList
   **/
  public static void PostAlerts(List<Product2> productList){

    List<ConnectApi.AnnouncementInput> toPost = new List<ConnectApi.AnnouncementInput>();

    for (Product2 p : productList) {
      ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
      ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

      ConnectApi.AnnouncementInput k = new ConnectApi.AnnouncementInput();
      k.expirationDate = Date.today().addDays(1);
      k.sendEmails = false;
      k.parentId = COLLABORATION_GROUP[0].Id;

      textSegmentInput.text = p.Name + ' ' + Constants.INVENTORY_LEVEL_LOW;
      messageBodyInput.messageSegments = new List<ConnectApi.messageSegmentInput>();
      messageBodyInput.messageSegments.add(textSegmentInput);
      k.body = messageBodyInput;

      toPost.add(k);
    }

    AnnouncementQueueable n = new AnnouncementQueueable();
    n.toPost = toPost;
    System.enqueueJob(n);
  }
}