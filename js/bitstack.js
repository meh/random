/********
* WTFPL *
********/

BitStack = function () {
    this._value    = 0;
    this._position = 0;
};

BitStack.prototype.push = function (bit) {
    if (bit) {
        this._value |= (1 << this._position);
    }
    else {
        this._value &= (Math.pow(2, this._position) - 1)
    }

    this._position++;
};

BitStack.prototype.pop = function () {
    if (this._position == 0) {
        throw new Error("No bits in the stack.");
    }

    return new Boolean(this._value & (1 << --this._position));
};

BitStack.prototype.toString = function () {
    return this._value.toString(2);
};
