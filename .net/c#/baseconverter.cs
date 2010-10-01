/*********************************************************************
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*                   Version 2, December 2004                         *
*                                                                    *
*  Copyleft meh.                                                     *
*                                                                    *
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION   *
*                                                                    *
*  0. You just DO WHAT THE FUCK YOU WANT TO.                         *
*********************************************************************/

class Number
{
    private string _value;
    private int    _base;
    private string _charset;

    public Number (string value, int oldBase, string charset)
    {
        _value   = value;
        _base    = oldBase;

        this.Charset = charset;
    }

    public Number (string value, int oldBase)
    {
        _value   = value;
        _base    = oldBase;

        this.Charset = Number.DefaultCharset();
    }

    public Number (int value)
    {
        _value   = value.ToString();
        _base    = 10;
        _charset = Number.DefaultCharset();
    }

    public string Value {
        get {
            return _value;
        }

        set {
            _value = value;
        }
    }

    public int Base {
        get {
            return _base;
        }

        set {
            if (value > _charset.Length) {
                throw new System.InvalidOperationException("The charset has to be long enough for the base.");
            }

            _base = value;
        }
    }

    public string Charset {
        get {
            return _charset;
        }

        set {
            if (value.Length < _base) {
                throw new System.InvalidOperationException("The charset has to be long enough for the base.");
            }

            _charset = value;
        }
    }

    public int ToInt ()
    {
        return System.Convert.ToInt32(this.ToBase(10).Value);
    }

    public Number ToBase (int newBase, string charset)
    {
        return Number.ToBase(_value, _base, _charset, newBase, charset);
    }

    public Number ToBase (int newBase)
    {
        return this.ToBase(newBase, _charset);
    }

    public override string ToString ()
    {
        return _value;
    }

    public static string DefaultCharset ()
    {
        return "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    }

    public static Number ToBase (string value, int oldBase, string charset, int newBase, string newCharset)
    {
        if (newBase > newCharset.Length) {
            throw new System.InvalidOperationException("The charset has to be long enough for the base.");
        }

        if (oldBase == newBase && charset == newCharset) {
            return new Number(value, oldBase, charset);
        }

        bool negative = false;

        if (value[0] == '-') {
            negative = true;

            value = value.Substring(1);
        }

        int val = 0;
        for (int i = 0; i < value.Length-1; i++) {
            val += Number.GetValueFromCharset(value[i], oldBase, charset);
            val *= oldBase;
        }
        val += Number.GetValueFromCharset(value[value.Length-1], oldBase, charset);

        if (newBase == 10 && newCharset == Number.DefaultCharset()) {
            return new Number(val);
        }

        if (val == 0) {
            return new Number("" + newCharset[0], newBase, newCharset);
        }

        string num = "";
        while (val != 0) {
            num += newCharset[val % newBase];
            val /= newBase;
        }

        char[] rev = num.ToCharArray();
        System.Array.Reverse(rev);
        num = new string(rev);

        return new Number((negative ? "-" + num : num), newBase, newCharset);
    }

    public static Number ToBase (string value, int oldBase, int newBase)
    {
        return Number.ToBase(value, oldBase, Number.DefaultCharset(), newBase, Number.DefaultCharset());
    }

    public static int GetValueFromCharset (char number, int oldBase, string charset)
    {
        int tmp = charset.IndexOf(number);

        if (tmp < 0 || tmp >= oldBase) {
            throw new System.InvalidOperationException("The passed number isn't of the given base.");
        }

        return tmp;
    }
}

class LOL
{
    public static int Main (string[] args)
    {
        if (args.Length < 5) {
            System.Console.WriteLine("Usage: <number> <base> <charset> <newBase> <newCharset>");
            return 1;
        }

        if (args[1] == "-") {
            args[1] = "10";
        }

        if (args[2] == "-") {
            args[2] = Number.DefaultCharset();
        }

        if (args[4] == "-") {
            args[4] = Number.DefaultCharset();
        }

        try {
            Number number = new Number(args[0], System.Convert.ToInt32(args[1]), args[2]);
            System.Console.WriteLine(number.ToBase(System.Convert.ToInt32(args[3]), args[4]));
        }
        catch (System.Exception e) {
            System.Console.WriteLine("Error: " + e.Message);
            
            return 2;
        }

        return 0;
    }
}
