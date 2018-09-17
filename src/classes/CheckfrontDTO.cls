/**
 * @description Contains DTO classes to convert Checkfront request JSON to SObject
 */
public class CheckfrontDTO {

    public class CheckfrontRequest {
        public Booking booking { get; set; }
    }



    public class Booking {
        public String status { get; set; }
        public String code { get; set; }
        public Long created_date { get; set; }
        public Long start_date { get; set; }
        public Long end_date { get; set; }
        public Fields fields { get; set; }
        public  Customer customer { get; set; }
        public Order order { get; set; }



        public Meeting_Room_Booking__c convertToSObject() {
            Meeting_Room_Booking__c payment = new Meeting_Room_Booking__c();
            payment.Status__c = this.status;
            payment.Code__c = this.code;
            payment.Created_Date__c = DateTime.newInstance(created_date * 1000);
            payment.Booking_End_Date__c =DateTime.newInstance(end_date * 1000);
            payment.Booking_Start_Date__c = DateTime.newInstance(start_date * 1000);
            System.debug('is ok');
            if ( this.fields != null ) {
                payment.Customer_Name__c = this.fields.customer_name;
                payment.Customer_Email__c = this.fields.customer_email;
            }
            if ( this.customer != null) {
                payment.Checkfront_Customer_ID__c = this.customer.code;
            }
            if ( this.order != null ) {
                payment.Order_Sub_Total__c = order.sub_total;
                payment.Order_Paid_Total__c = order.paid_total;
                payment.Order_Tax_Total__c = order.tax_total;
                payment.Order_Total__c = order.total;
            }
            if ( this.order.items.item != null) {
                payment.Property__c = order.items.item.sku.substringBefore('-');
                payment.Room__c = order.items.item.sku.substringAfter('-');

            }
            return payment;
        }
    }

    public class Fields {
        public String customer_name { get; set; }
        public String customer_email { get; set; }

    }

    public class Customer {
        public String code { get; set; }
    }

    public class Order {
        public Decimal sub_total { get; set; }
        public Decimal paid_total { get; set; }
        public Decimal tax_total { get; set; }
        public Decimal total { get; set; }
        public Items items { get; set; }
    }

    public class Items {
        public Item item  { get; set; }
    }

    public class Item {
        public string sku { get; set; }
    }
}