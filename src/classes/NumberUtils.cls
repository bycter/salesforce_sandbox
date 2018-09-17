public class NumberUtils {
    private static final String CURRENCY_SYMBOL = '£';

    public static String getOrdinalNumber(Integer numeric) {
        String ordinalNumber = 'th';
        if (numeric == 1) {
            ordinalNumber = 'st';
        } else if (numeric == 2) {
            ordinalNumber = 'nd';
        } else if (numeric == 3) {
            ordinalNumber = 'rd';
        }
        return ordinalNumber;
    }

    public static Map<Decimal, String> convertNumberToWords(List<Decimal> numbers) {
        Map<Decimal, String> outputValues = new Map<Decimal, String>();
        if (numbers != null && !numbers.isEmpty()) {
            NumberToWordsConverter.AbstractProcessor processor = new NumberToWordsConverter.BritishPoundsProcessor();

            for (Decimal val : numbers) {
                outputValues.put(val, processor.getName(val));
            }
        }
        return outputValues;
    }

    public static Decimal convertNullToZero(Decimal num) {
        return num == null ? 0 : num;
    }

    public static String convertMonthsToYears(Integer monthCount) {
        String result = '';
        Integer years = Integer.valueOf(monthCount) / 12;
        Integer months = Math.mod(Integer.valueOf(monthCount), 12);
        if (years > 1) {
            result = years + ' years ';
        } else if (years == 1) {
            result = years + ' year ';
        }
        if (months > 1) {
            result = result + months + ' months ';
        } else if (months == 1) {
            result = result + months + ' month ';
        }
        return result;
    }

    public static String convertToCurrency(Decimal num) {
        String amount;
        if ( num != null ) {
            amount = CURRENCY_SYMBOL + num.format();
            if ( !amount.contains('.') ) {
                amount = amount + '.00';
            } else {
                Integer dotPos = amount.indexOf('.');
                if (amount.length() - dotPos < 3) {
                    amount = amount + '0';
                }
            }
        }
        return amount;
    }
}