public with sharing class NumberToWordsConverter {
    /**
     * Change this scale to support American and modern British value (short scale)
     * or Traditional British value (long scale)
     */
    public enum Scale {SHORT_MODE, LONG_MODE}
    public static Scale SCALE_MODE = Scale.SHORT_MODE;

    /**
     * See http://www.wordiq.com/definition/Names_of_large_numbers
     */
    private static Map<Integer, ScaleUnit> SCALE_UNITS = new Map<Integer, ScaleUnit>{
        63 => new ScaleUnit('vigintillion', 'decilliard'),
        60 => new ScaleUnit('novemdecillion', 'decillion'),
        57 => new ScaleUnit('octodecillion', 'nonilliard'),
        54 => new ScaleUnit('septendecillion', 'nonillion'),
        51 => new ScaleUnit('sexdecillion', 'octilliard'),
        48 => new ScaleUnit('quindecillion', 'octillion'),
        45 => new ScaleUnit('quattuordecillion', 'septilliard'),
        42 => new ScaleUnit('tredecillion', 'septillion'),
        39 => new ScaleUnit('duodecillion', 'sextilliard'),
        36 => new ScaleUnit('undecillion', 'sextillion'),
        33 => new ScaleUnit('decillion', 'quintilliard'),
        30 => new ScaleUnit('nonillion', 'quintillion'),
        27 => new ScaleUnit('octillion', 'quadrilliard'),
        24 => new ScaleUnit('septillion', 'quadrillion'),
        21 => new ScaleUnit('sextillion', 'trilliard'),
        18 => new ScaleUnit('quintillion', 'trillion'),
        15 => new ScaleUnit('quadrillion', 'billiard'),
        12 => new ScaleUnit('trillion', 'billion'),
        9 => new ScaleUnit('billion', 'milliard'),
        6 => new ScaleUnit('million', 'million'),
        3 => new ScaleUnit('thousand', 'thousand'),
        2 => new ScaleUnit('hundred', 'hundred'),
        -1 => new ScaleUnit('tenth', 'tenth'),
        -2 => new ScaleUnit('hundredth', 'hundredth'),
        -3 => new ScaleUnit('thousandth', 'thousandth'),
        -4 => new ScaleUnit('ten-thousandth', 'ten-thousandth'),
        -5 => new ScaleUnit('hundred-thousandth', 'hundred-thousandth'),
        -6 => new ScaleUnit('millionth', 'millionth'),
        -7 => new ScaleUnit('ten-millionth', 'ten-millionth'),
        -8 => new ScaleUnit('hundred-millionth', 'hundred-millionth'),
        -9 => new ScaleUnit('billionth', 'milliardth'),
        -10 => new ScaleUnit('ten-billionth', 'ten-milliardth'),
        -11 => new ScaleUnit('hundred-billionth', 'hundred-milliardth'),
        -12 => new ScaleUnit('trillionth', 'billionth'),
        -13 => new ScaleUnit('ten-trillionth', 'ten-billionth'),
        -14 => new ScaleUnit('hundred-trillionth', 'hundred-billionth'),
        -15 => new ScaleUnit('quadrillionth', 'billiardth'),
        -16 => new ScaleUnit('ten-quadrillionth', 'ten-billiardth'),
        -17 => new ScaleUnit('hundred-quadrillionth', 'hundred-billiardth'),
        -18 => new ScaleUnit('quintillionth', 'trillionth'),
        -19 => new ScaleUnit('ten-quintillionth', 'ten-trillionth'),
        -20 => new ScaleUnit('hundred-quintillionth', 'hundred-trillionth'),
        -21 => new ScaleUnit('sextillionth', 'trilliardth'),
        -22 => new ScaleUnit('ten-sextillionth', 'ten-trilliardth'),
        -23 => new ScaleUnit('hundred-sextillionth', 'hundred-trilliardth'),
        -24 => new ScaleUnit('septillionth', 'quadrillionth'),
        -25 => new ScaleUnit('ten-septillionth', 'ten-quadrillionth'),
        -26 => new ScaleUnit('hundred-septillionth', 'hundred-quadrillionth')
    };

    public class ScaleUnit {
        private List<String> names;

        private ScaleUnit(String shortName, String longName) {
            this.names = new List<String>{ shortName, longName };
        }

        public String getName(Integer index) {
            return this.names.get(index);
        }
    }

    public abstract class AbstractProcessor {
        public final String UNION_AND = 'and';
        public final String SEPARATOR = ' ';
        public final Integer NO_VALUE = -1;

        public String getName(Integer value) {
            return getName(String.valueOf(value));
        }

        public String getName(Decimal value) {
            return getName(String.valueOf(value));
        }

        public String getName(long value) {
            return getName(String.valueOf(value));
        }

        public abstract String getName(String value);
    }

    public class UnitProcessor extends AbstractProcessor {
        private final List<String> TOKENS = new List<String>{
            'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine',
            'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
        };

        public override String getName(String value) {
            List<String> buffer = new List<String>();

            Integer offset = NO_VALUE;
            Integer numb;
            if (value.length() > 3) {
                numb = Integer.valueOf(value.substring(value.length() - 3));
            } else {
                numb = Integer.valueOf(value);
            }
            numb = Math.mod(numb, 100);
            if (numb < 10) {
                offset = Math.mod(numb, 10) - 1;
                //numb /= 10;
            } else if (numb < 20) {
                offset = Math.mod(numb, 20) - 1;
                //numb /= 100;
            }

            if (offset != NO_VALUE && offset < TOKENS.size()) {
                buffer.add(TOKENS[offset]);
            }
            return String.join(buffer, '');
        }
    }

    public class TensProcessor extends AbstractProcessor {
        private final String UNION_SEPARATOR = ' ';
        private final List<String> TOKENS = new List<String>{
            'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
        };

        private UnitProcessor unitProcessor = new UnitProcessor();

        public override String getName(String value) {
            List<String> buffer = new List<String>();
            Boolean tensFound = false;

            Integer numb;
            if (value.length() > 3) {
                numb = Integer.valueOf(value.substring(value.length() - 3));
            } else {
                numb = Integer.valueOf(value);
            }
            numb = Math.mod(numb, 100); // keep only two digits
            if (numb >= 20) {
                buffer.add(TOKENS[(numb / 10) - 2]);
                numb = Math.mod(numb, 10);
                tensFound = true;
            } else {
                numb = Math.mod(numb, 20);
            }

            if (numb != 0) {
                if (tensFound) {
                    buffer.add(UNION_SEPARATOR);
                }
                buffer.add(unitProcessor.getName(numb));
            }

            return String.join(buffer, '');
        }
    }

    public class HundredProcessor extends AbstractProcessor {
        private final Integer EXPONENT = 2;
        private UnitProcessor unitProcessor = new UnitProcessor();
        private TensProcessor tensProcessor = new TensProcessor();

        public override String getName(String value) {
            List<String> buffer = new List<String>();

            Integer numb;
            if (String.isBlank(value)) {
                numb = 0;
            } else if (value.length() > 4) {
                numb = Integer.valueOf(value.substring(value.length() - 4));
            } else {
                numb = Integer.valueOf(value);
            }
            numb = Math.mod(numb, 1000);// keep at least three digits

            if (numb >= 100) {
                buffer.add(unitProcessor.getName(numb / 100));
                buffer.add(SEPARATOR);
                buffer.add(SCALE_UNITS.get(EXPONENT).getName(SCALE_MODE.ordinal()));
            }

            String tensName = tensProcessor.getName(Math.mod(numb, 100));

            if (!String.isBlank(tensName) && (numb >= 100)) {
                buffer.add(SEPARATOR);
            }
            if (!String.isBlank(tensName)) {
                buffer.add(UNION_AND + SEPARATOR);
            }
            buffer.add(tensName);

            return String.join(buffer, '');
        }
    }

    public class CompositeBigProcessor extends AbstractProcessor {
        private HundredProcessor hundredProcessor = new HundredProcessor();
        private AbstractProcessor lowProcessor;
        private Integer exponent;

        public CompositeBigProcessor(Integer exponent) {
            if (exponent <= 3) {
                lowProcessor = hundredProcessor;
            } else {
                lowProcessor = new CompositeBigProcessor(exponent - 3);
            }
            this.exponent = exponent;
        }

        public String getToken() {
            if (SCALE_UNITS.containsKey(getPartDivider())) {
                return SCALE_UNITS.get(getPartDivider()).getName(SCALE_MODE.ordinal());
            }
            return '';
        }

        public AbstractProcessor getHighProcessor() {
            return hundredProcessor;
        }

        public AbstractProcessor getLowProcessor() {
            return lowProcessor;
        }

        public Integer getPartDivider() {
            return exponent;
        }

        public override String getName(String value) {
            List<String> buffer = new List<String>();

            String high, low;
            if (value.length() < getPartDivider()) {
                high = '';
                low = value;
            } else {
                Integer index = value.length() - getPartDivider();
                high = value.substring(0, index);
                low = value.substring(index);
            }

            String highName = getHighProcessor().getName(high);
            String lowName = getLowProcessor().getName(low);

            if (!String.isBlank(highName)) {
                highName = highName.startsWith(UNION_AND + SEPARATOR) ? highName.replace(UNION_AND + SEPARATOR, '') : highName;
                buffer.add(highName);
                buffer.add(SEPARATOR);
                buffer.add(getToken());

                if (!String.isBlank(lowName)) {
                    buffer.add(SEPARATOR);
                }
            }

            if (!String.isBlank(lowName)) {
                buffer.add(lowName);
            }

            return String.join(buffer, '');
        }
    }

    public class DefaultProcessor extends AbstractProcessor {
        private final String MINUS = 'minus';
        private final String ZERO_TOKEN = 'zero';

        private AbstractProcessor processor = new CompositeBigProcessor(63);

        public override String getName(String value) {
            Boolean negative = false;
            if (value.startsWith('-')) {
                negative = true;
                value = value.substring(1);
            }

            Integer decimals = value.indexOf('.');
            String decimalValue = null;
            if (0 <= decimals) {
                decimalValue = value.substring(decimals + 1);
                value = value.substring(0, decimals);
            }

            String name = processor.getName(value);
            if (String.isBlank(name)) {
                name = ZERO_TOKEN;
            } else if (negative) {
                name = MINUS + SEPARATOR + name;
            }

            if (String.isNotBLank(decimalValue)) {
                name = name + SEPARATOR + processor.getName(decimalValue);

                Integer ln = -decimalValue.length();
                if (SCALE_UNITS.containsKey(ln)) {
                    name += SEPARATOR + SCALE_UNITS.get(ln).getName(SCALE_MODE.ordinal());
                }
            }
            return name;
        }
    }

    public class BritishPoundsProcessor extends AbstractProcessor {
        private final String MINUS = 'minus';
        private final String ZERO_TOKEN = 'zero';
        private final String POUND = 'pound';
        private final String PENCE = 'pence';

        private AbstractProcessor processor = new CompositeBigProcessor(18);

        public override String getName(String value) {
            Boolean negative = false;
            if (value.startsWith('-')) {
                negative = true;
                value = value.substring(1);
            }

            Integer decimals = value.indexOf('.');
            String decimalValue = null;
            if (0 <= decimals) {
                decimalValue = value.substring(decimals + 1);
                if (decimalValue.length() < 2) {
                    decimalValue = decimalValue + '0';
                } else if (decimalValue.length() > 2) {
                    decimalValue = decimalValue.substring(0, 2);
                }
                decimalValue = Integer.valueOf(decimalValue) != 0 ? decimalValue : null;
                value = value.substring(0, decimals);
            }

            String name = processor.getName(value);
            if (String.isBlank(name)) {
                name = ZERO_TOKEN;
            } else if (negative) {
                name = MINUS + SEPARATOR + name;
            }

            String poundsWord = SEPARATOR + POUND;
            if (!name.equalsIgnoreCase('one')) {
                poundsWord += 's';
            }
            name += poundsWord;
            name = this.capitalizeName(name);


            if (String.isNotBlank(decimalValue)) {
                String decimalName = processor.getName(decimalValue) + SEPARATOR + PENCE;
                name += SEPARATOR + this.capitalizeName(decimalName);
            }
            return name;
        }

        private String capitalizeName(String name) {
            List<String> parts = new List<String>();
            for (String part : name.split(SEPARATOR)) {
                parts.add(UNION_AND.equalsIgnoreCase(part) ? part: part.capitalize());
            }
            return String.join(parts, SEPARATOR);
        }
    }
}