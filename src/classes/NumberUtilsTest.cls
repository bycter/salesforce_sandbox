@isTest
public class NumberUtilsTest {
    @isTest
    public static void testOrdinalNumbers() {
        System.assertEquals(NumberUtils.getOrdinalNumber(1), 'st');
        System.assertEquals(NumberUtils.getOrdinalNumber(2), 'nd');
        System.assertEquals(NumberUtils.getOrdinalNumber(3), 'rd');
        System.assertEquals(NumberUtils.getOrdinalNumber(100), 'th');
    }
}