@isTest
private class NumberToWordsConverterTest {
    static String TEST_STRING1 = 'Sixteen Thousand Six Hundred and Sixty Six Pounds and Sixty Seven Pence';
    static String TEST_STRING2 = 'Five Thousand and Fifty Pounds';
    static String TEST_STRING3 = 'Five Thousand and Five Pounds';
    static String TEST_STRING4 = 'Three Million Five Hundred and Twenty Five Thousand Two Hundred and Fifty Pounds';

    @isTest static void testStringConvertion() {
        NumberToWordsConverter.AbstractProcessor processor = new NumberToWordsConverter.BritishPoundsProcessor();
        System.assertEquals(TEST_STRING1, processor.getName('16666.67'));
    }
    
    @isTest static void testValueConversion() {
        NumberToWordsConverter.AbstractProcessor processor = new NumberToWordsConverter.BritishPoundsProcessor();
        System.assertEquals(TEST_STRING1, processor.getName(16666.67), '16666.67 > ' + TEST_STRING1);
        System.assertEquals(TEST_STRING2, processor.getName(5050), '5050 > ' + TEST_STRING2);
        System.assertEquals(TEST_STRING3, processor.getName(5005), '5005 > ' + TEST_STRING3);
        System.assertEquals(TEST_STRING4, processor.getName(3525250), '3525250 >' + TEST_STRING4);
    }

    @isTest static void testLongConvertion() {
        NumberToWordsConverter.AbstractProcessor processor = new NumberToWordsConverter.DefaultProcessor();
        List<Long> values = new List<Long> {
            0,
            1,
            4,
            10,
            12,
            100,
            108,
            299,
            1000,
            1003,
            2040,
            45213,
            100000,
            100005,
            100010,
            202020,
            202022,
            999999,
            1000000,
            1000001,
            10000000,
            10000007,
            99999999
        };

        for (long val : values) {
            System.assertNotEquals('', processor.getName(val));
        }
        System.assertNotEquals('', processor.getName(-11.11));
    }

    @isTest static void testNumberUtils() {
        List<Decimal> numbers = new List<Decimal> {
            -12395.94,
            0,
            42973.93,
            100000,
            100005,
            100010,
            202020,
            202022,
            999999,
            1000000,
            1000001,
            10000000,
            10000007,
            99999999
        };

        Map<Decimal, String> values = NumberUtils.convertNumberToWords(numbers);
        System.assertNotEquals(0, values.size());
    }
}