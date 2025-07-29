"""lt
# Python Calculator Module
## モジュールの説明
Pythonで実装された計算機モジュールです。

### 提供する機能
- **基本演算**: 加算、減算、乗算、除算
- **数学関数**: 平方根、累乗
- *型安全性*: 型ヒントによる安全な実装

```python
def calculate(x: float, y: float, operation: str) -> float:
    if operation == "add":
        return x + y
    elif operation == "multiply":
        return x * y
```

```algorithm
Algorithm: Square Root Calculation
Input: number (non-negative)
Output: square root or error
1: if number < 0 then
2:     return Error("Negative input")
3: else
4:     return sqrt(number)
5: end
```
"""

import math
from typing import Union

def add(a: float, b: float) -> float:
    """Add two numbers"""
    return a + b

def subtract(a: float, b: float) -> float:
    """Subtract two numbers"""
    return a - b

def multiply(a: float, b: float) -> float:
    """Multiply two numbers"""
    return a * b

def divide(a: float, b: float) -> Union[float, str]:
    """Divide two numbers with zero check"""
    if b == 0:
        return "Error: Division by zero"
    return a / b

def sqrt_safe(x: float) -> Union[float, str]:
    """Calculate square root with negative check"""
    if x < 0:
        return "Error: Negative input"
    return math.sqrt(x)

if __name__ == "__main__":
    print("Python Calculator")
    print(f"5 + 3 = {add(5, 3)}")
    print(f"10 / 2 = {divide(10, 2)}")
    print(f"√16 = {sqrt_safe(16)}")
    print(f"√(-4) = {sqrt_safe(-4)}")