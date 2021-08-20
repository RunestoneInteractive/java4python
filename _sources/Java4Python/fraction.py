class Fraction:
    def __init__(self, num, den):
        """
        :param num: The top of the fraction
        :param den: The bottom of the fraction
        """
        self.num = num
        self.den = den

    def __repr__(self):
        if self.num > self.den:
            retWhole = self.num / self.den
            retNum = self.num - (retWhole * self.den)
            return str(retWhole) + " " + str(retNum) + "/" + str(self.den)
        else:
            return str(self.num) + "/" + str(self.den)

    def show(self):
        print(self.num, "/", self.den)

    def __add__(self, other):
        # convert to a fraction
        other = self.toFract(other)
        newnum = self.num * other.den + self.den * other.num
        newden = self.den * other.den
        common = gcd(newnum, newden)
        return Fraction(newnum / common, newden / common)

    def __radd__(self, leftNum):
        other = self.toFract(leftNum)
        newnum = self.num * other.den + self.den * other.num
        newden = self.den * other.den
        common = gcd(newnum, newden)
        return Fraction(newnum / common, newden / common)

    def __cmp__(self, other):
        num1 = self.num * other.den
        num2 = self.den * other.num
        if num1 < num2:
            return -1
        else:
            if num1 == num2:
                return 0
            else:
                return 1

    def toFract(self, n):
        if isinstance(n, int):
            other = Fraction(n, 1)
        elif isinstance(n, float):
            wholePart = int(n)
            fracPart = n - wholePart
            # convert to 100ths???
            fracNum = int(fracPart * 100)
            newNum = wholePart * 100 + fracNum
            other = Fraction(newNum, 100)
        elif isinstance(n, Fraction):
            other = n
        else:
            print("Error: cannot add a fraction to a ", type(n))
            return None
        return other


def gcd(m, n):
    """
    A helper function for Fraction
    """
    while m % n != 0:
        oldm = m
        oldn = n
        m = oldn
        n = oldm % oldn
    return n
