/*lt
# Main Function Documentation
## プログラムの概要
このRustプログラムは基本的な計算機能を提供します。

### 機能リスト
- **四則演算**: 加算、減算、乗算、除算
- **エラーハンドリング**: ゼロ除算の検出
- *高速処理*: 最適化されたアルゴリズム

```rust
fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

```algorithm
Algorithm: Division with Zero Check
Input: dividend, divisor
Output: result or error
1: if divisor = 0 then
2:     return Error("Division by zero")
3: else
4:     return dividend / divisor
5: end
```
*/

fn main() {
    println!("Hello, world!");
    
    let result = add(5, 3);
    println!("5 + 3 = {}", result);
    
    match divide(10, 2) {
        Ok(result) => println!("10 / 2 = {}", result),
        Err(e) => println!("Error: {}", e),
    }
}

fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        Err("Division by zero".to_string())
    } else {
        Ok(a / b)
    }
}