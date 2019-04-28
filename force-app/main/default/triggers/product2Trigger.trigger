trigger product2Trigger on Product2 (after update) {
    Product2Helper.AfterUpdate((List<Product2>)Trigger.new);
}