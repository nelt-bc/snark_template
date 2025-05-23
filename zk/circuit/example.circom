template Example() {
    signal input a;
    signal input b;
    signal input c;
    signal output out;

    signal tmp;
    tmp <== a + b;
    out <== tmp * c;
}

component main = Example();