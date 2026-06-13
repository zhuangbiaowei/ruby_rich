#!/usr/bin/env ruby
# frozen_string_literal: true
# 演示：LaTeX 数学公式 → Unicode 转换
require_relative "../lib/ruby_rich"

puts RubyRich::RichText.markup("[bold cyan]LaTeX → Unicode 数学公式演示 (v0.5.0 新增)[/bold cyan]")
puts "=" * 60

puts RubyRich::RichText.markup("\n[bold]1. 行内公式[/bold]")
puts RubyRich.markdown(<<~'MD', width: 60)
欧拉恒等式：$e^{i\pi} + 1 = 0$

勾股定理：$a^{2} + b^{2} = c^{2}$

分数与根式：$\frac{-b \pm \sqrt{b^{2} - 4ac}}{2a}$

微积分：$\int_{0}^{\infty} e^{-x} dx = 1$
MD

puts RubyRich::RichText.markup("\n[bold]2. 块级公式[/bold]")
puts RubyRich.markdown(<<~'MD', width: 60)
麦克斯韦方程组之一：
$$
\nabla \cdot \mathbf{E} = \frac{\rho}{\epsilon_{0}}
$$

求和公式：
$$
\sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$
MD

puts RubyRich::RichText.markup("\n[bold]3. 更多符号[/bold]")
puts RubyRich.markdown(<<~'MD', width: 60)
不等式：$x \leq y \leq z$，$a \neq b$

集合：$x \in A \subseteq B$，$\forall x \exists y$

箭头：$f: A \to B$，$g \leftarrow C$

运算符：$\alpha \times \beta \pm \gamma \cdot \delta$

大号运算符：$\prod_{i=1}^{n} a_i$，$\bigcup_{k=1}^{\infty} A_k$

分段函数 (cases)：
$$
\begin{cases}
x & \text{if } x \geq 0 \\
-x & \text{otherwise}
\end{cases}
$$
MD

puts RubyRich::RichText.markup("[green]✅ LaTeX 数学公式演示完成[/green]")
