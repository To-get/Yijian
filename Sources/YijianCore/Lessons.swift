import Foundation

public struct Lesson: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let steps: [LessonStep]
}
public struct LessonStep: Sendable {
    public let title: String
    public let body: String
    public let question: String
    public let answers: [String]
    public let correct: Int
    public let explanation: String
}

public enum Lessons {
    public static func forGame(_ kind: GameKind) -> [Lesson] {
        switch kind {
        case .chess: return [
            Lesson(id: "chess-start", title: "认识棋盘与棋子", summary: "从第一步开始，理解六种棋子的走法。", steps: [
                LessonStep(title: "64 格里的第一课", body: "国际象棋使用 8 × 8 棋盘，每方各有 16 枚棋子。摆棋时右下角是浅色格。白方先走，双方轮流走一步。你的目标是将杀对方的王。", question: "哪一方先走？", answers: ["白方", "黑方", "双方同时走"], correct: 0, explanation: "白方先走。获胜的关键是让对方的王遭受攻击且无法解救。"),
                LessonStep(title: "车、象、后：直线的力量", body: "车沿横线、竖线走；象沿斜线走；后兼有车与象的走法。三者都不能越过其他棋子。落到对方棋子所在格时，吃掉该棋子。", question: "哪种棋子只能沿斜线走？", answers: ["车", "象", "后"], correct: 1, explanation: "象只能斜行，因此始终留在同一种颜色的格子上。"),
                LessonStep(title: "马与兵：不同的节奏", body: "马走“日”字，可以跳过棋子。兵通常向前走一格，从初始位置可走两格，斜前方吃子。兵到达对方底线时，必须升变为后、车、象或马。", question: "兵怎样吃子？", answers: ["正前方", "斜前方", "任意方向"], correct: 1, explanation: "兵直走、斜吃。弈间会在升变时让你选择棋子。")]),
            Lesson(id: "chess-rules", title: "将军、将杀与特殊规则", summary: "理解胜负，认识易位和吃过路兵。", steps: [
                LessonStep(title: "先保护自己的王", body: "王每次向任意方向走一格。王受攻击称为“将军”，必须通过移动王、吃掉进攻子或挡住攻击来解除。不能让自己的王留在被攻击的位置。", question: "被将军时能否忽略它，进攻别处？", answers: ["可以", "不可以"], correct: 1, explanation: "必须先解除将军。弈间只显示合法落点。"),
                LessonStep(title: "将杀与逼和", body: "被将军且没有任何合法应对是将杀，对方获胜。轮到走棋的一方没有合法着法、但王没有被将军，是逼和。子力不足、三次重复和五十步规则也可能形成和棋。练习中符合引擎的可申和条件时自动裁定。", question: "没有合法着法，但王未被将军，结果是？", answers: ["输棋", "和棋", "跳过一回合"], correct: 1, explanation: "这是逼和；它与中国象棋的困毙判负不同。"),
                LessonStep(title: "两条特别的规则", body: "王车易位：王和相关的车都未动过、之间没有棋子，王未被将军，也不经过或到达被攻击格；王朝车方向走两格，车跨过王。吃过路兵：对方兵刚从原位走两格、与你的兵并排时，可立即按它只走一格的位置斜吃。", question: "能否通过王车易位逃离正在遭受的将军？", answers: ["能", "不能"], correct: 1, explanation: "王正在被将军时不能易位。选中王后点击两格外的合法落点即可易位。")]),
            Lesson(id: "chess-training", title: "开始你的第一局", summary: "用三个习惯建立稳定的思考方式。", steps: [
                LessonStep(title: "中心、出子、王的安全", body: "开局争取控制中心，让马和象参与战斗，适时完成王车易位。每次落子前检查对手的将军、吃子和直接威胁。先从启蒙难度开始，复盘时比较自己的选择与引擎建议。", question: "落子前应先检查什么？", answers: ["是否走得足够快", "对手的将军、吃子与威胁", "是否每步都用后"], correct: 1, explanation: "先看威胁，再找机会。一次复盘专注一个可改进的决策就很好。")])
        ]
        case .xiangqi: return [
            Lesson(id: "xiangqi-start", title: "走进楚河汉界", summary: "认识九宫、河界和七种棋子。", steps: [
                LessonStep(title: "棋子落在线的交点", body: "中国象棋有 9 条竖线、10 条横线，每方 16 子。红方先走。将帅和士在九宫内活动；象不能过河。目标是将死或困毙对方。", question: "中国象棋的棋子放在哪里？", answers: ["格子中央", "线的交点"], correct: 1, explanation: "落在交点上。界面下方为红方，默认由你执红。"),
                LessonStep(title: "车走直，马走日，象飞田", body: "车横竖直走，不能越子。马走日字，若邻近的直行位置有棋子，就被“蹩马腿”。象走田字，田字中间有棋子时被“塞象眼”，并且不能过河。", question: "中国象棋的马能无条件跳过其他棋子吗？", answers: ["能", "不能，可能被蹩马腿"], correct: 1, explanation: "这与国际象棋的马不同；先检查马腿位置。"),
                LessonStep(title: "炮、兵卒与九宫", body: "炮平时像车一样走，吃子时必须恰好隔一个棋子。兵卒未过河只能前进一步；过河后还可左右平走，始终不能后退。士斜走一格，将帅横竖走一格，都不能离开九宫。", question: "炮吃子需要隔几个棋子？", answers: ["零个", "恰好一个", "任意多个"], correct: 1, explanation: "这个隔着的棋子叫炮架，可以是任意一方的棋子。")]),
            Lesson(id: "xiangqi-rules", title: "将军、照面与胜负", summary: "避免常见误走，理解比赛何时结束。", steps: [
                LessonStep(title: "将帅不能直接照面", body: "两方将帅不能在同一竖线上无子相隔。移动中间的遮挡棋子前，要检查是否会造成照面。被将军后必须立即应将。", question: "移开遮挡棋子造成将帅照面，是否合法？", answers: ["合法", "不合法"], correct: 1, explanation: "将帅照面属于非法局面，弈间会阻止这样的着法。"),
                LessonStep(title: "困毙也算输", body: "被将军且无法解救称为将死。即使未被将军，如果轮到自己却没有合法着法，也因困毙而输棋。重复局面涉及长将、长捉等规则，由 Fairy-Stockfish 的象棋规则裁定。", question: "无合法着法且未被将军时，中国象棋如何判？", answers: ["和棋", "该方负", "跳过回合"], correct: 1, explanation: "中国象棋判困毙方负，不同于国际象棋的逼和。")]),
            Lesson(id: "xiangqi-training", title: "读棋谱，练配合", summary: "从“炮二平五”学会记录与复盘。", steps: [
                LessonStep(title: "把落子变成可以回看的思路", body: "“炮二平五”表示第二路的炮平移到第五路；进为向对方、退为向己方。红方使用中文数字，黑方使用阿拉伯数字。初学时优先练习车马炮配合、保护无根子，每局结束回看一次关键失误。", question: "“平”表示什么方向？", answers: ["向前", "向后", "横向移动"], correct: 2, explanation: "“平”表示横向移动。你也可以直接点击棋谱中的某一步回到对应局面。")])
        ]
        case .go: return [
            Lesson(id: "go-start", title: "黑白之间，从一口气开始", summary: "学习落子、气、连接和提子。", steps: [
                LessonStep(title: "从 9 路小棋盘开始", body: "围棋把棋子放在线的交点。黑先白后，双方轮流落一子；棋子落下后不移动。弈间支持 9、13、19 路，9 路更容易看清整盘，适合入门。", question: "落下的围棋棋子可以移到另一处吗？", answers: ["可以", "不可以"], correct: 1, explanation: "棋子不会移动，只有被提掉时才离开棋盘。"),
                LessonStep(title: "什么是气？", body: "与棋子上下左右相邻的空交点叫气，斜向不算。上下左右直接相连的同色棋子形成一块，共享气。棋块的最后一口气被占据后，整块被提走。", question: "棋子斜对角的空点算气吗？", answers: ["算", "不算"], correct: 1, explanation: "气只计算上下左右。注意连接能共享气，也可能让整块同时陷入危险。"),
                LessonStep(title: "打吃与提子", body: "一块棋只剩一口气称为被打吃。可以通过延长、连接或吃掉对方来逃脱。通常不能落在让自己的整块立即无气的位置；如果这步先提掉对方，获得了气，则可以下。", question: "一块棋被打吃，说明它还有几口气？", answers: ["一口", "两口", "零口"], correct: 0, explanation: "剩一口气。下棋时先检查自己的弱棋是否需要补强。")]),
            Lesson(id: "go-rules", title: "劫、眼与终局", summary: "认识围棋规则里最重要的几个概念。", steps: [
                LessonStep(title: "劫：不能立刻回到原样", body: "劫的限制防止双方立即反复提回同一颗棋子。本应用采用禁止全局同形的设置：一般落子不能重复此前的棋盘状态。遇到劫，要先到别处寻找机会。", question: "刚被提掉一颗劫子，能否立即提回还原棋盘？", answers: ["可以", "不可以"], correct: 1, explanation: "不能立即还原，必须先在别处落子，改变局面。"),
                LessonStep(title: "两只真眼与活棋", body: "“眼”是被己方棋子围住的空点。一块棋若有两只独立的真眼，通常不能被提掉；假眼则不能提供同样的保护。初学时先练习连接和做活，不急于追杀。", question: "以下哪种形状通常最安全？", answers: ["两只独立真眼", "只有一只眼", "没有气"], correct: 0, explanation: "两只真眼让对手无法同时填满所有气。复杂死活需要具体计算。"),
                LessonStep(title: "停一手与数子", body: "觉得没有必要继续落子时可以停一手。双方连续停一手后，按中国规则计分：比较活子及所围空点，白方贴 7.5 目。弈间使用 GNU Go 自动估计死活并数子，复杂局面可在复盘中继续研究；未收完的官子会影响结果。", question: "什么时候进入终局计分？", answers: ["一方停一手", "双方连续停一手", "棋盘下满"], correct: 1, explanation: "双方连续停一手后计分。不要在双方仍有明显可争取的空点时急着停。")]),
            Lesson(id: "go-training", title: "先角、后边、再中腹", summary: "用小棋盘建立方向感。", steps: [
                LessonStep(title: "每一手都问自己一个问题", body: "角部借助两条边界更容易围地，边上其次，中腹更难。练习时先看双方的气与弱棋，再考虑围地。GNU Go 的四档难度调整搜索强度，档位不是业余段位；它适合入门陪练，不能替代高水平围棋分析。", question: "入门复盘时最应该优先检查什么？", answers: ["双方棋块的气与连接", "只统计吃子数", "只往中间下"], correct: 0, explanation: "吃子数量不是胜负本身。气、连接和围地一起决定局面的好坏。")])
        ]
        }
    }
}
