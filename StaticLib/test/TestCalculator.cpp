#include <gtest/gtest.h>
#include "Calculator.h"

// ============================================================================
// Add 函數測試
// ============================================================================
TEST(CalculatorTest, Add_PositiveNumbers)
{
    EXPECT_EQ(5, Calculator::Add(2, 3));
    EXPECT_EQ(100, Calculator::Add(50, 50));
}

TEST(CalculatorTest, Add_NegativeNumbers)
{
    EXPECT_EQ(-5, Calculator::Add(-2, -3));
    EXPECT_EQ(-1, Calculator::Add(-5, 4));
}

TEST(CalculatorTest, Add_Zero)
{
    EXPECT_EQ(5, Calculator::Add(5, 0));
    EXPECT_EQ(0, Calculator::Add(0, 0));
}

// ============================================================================
// Subtract 函數測試
// ============================================================================
TEST(CalculatorTest, Subtract_PositiveNumbers)
{
    EXPECT_EQ(2, Calculator::Subtract(5, 3));
    EXPECT_EQ(0, Calculator::Subtract(10, 10));
}

TEST(CalculatorTest, Subtract_NegativeNumbers)
{
    EXPECT_EQ(1, Calculator::Subtract(-2, -3));
    EXPECT_EQ(-9, Calculator::Subtract(-5, 4));
}

TEST(CalculatorTest, Subtract_Zero)
{
    EXPECT_EQ(5, Calculator::Subtract(5, 0));
    EXPECT_EQ(-5, Calculator::Subtract(0, 5));
}

// ============================================================================
// Multiply 函數測試
// ============================================================================
TEST(CalculatorTest, Multiply_PositiveNumbers)
{
    EXPECT_EQ(6, Calculator::Multiply(2, 3));
    EXPECT_EQ(100, Calculator::Multiply(10, 10));
}

TEST(CalculatorTest, Multiply_NegativeNumbers)
{
    EXPECT_EQ(6, Calculator::Multiply(-2, -3));
    EXPECT_EQ(-20, Calculator::Multiply(-5, 4));
}

TEST(CalculatorTest, Multiply_Zero)
{
    EXPECT_EQ(0, Calculator::Multiply(5, 0));
    EXPECT_EQ(0, Calculator::Multiply(0, 0));
}

// ============================================================================
// Divide 函數測試
// ============================================================================
TEST(CalculatorTest, Divide_PositiveNumbers)
{
    EXPECT_DOUBLE_EQ(2.0, Calculator::Divide(6, 3));
    EXPECT_DOUBLE_EQ(2.5, Calculator::Divide(5, 2));
}

TEST(CalculatorTest, Divide_NegativeNumbers)
{
    EXPECT_DOUBLE_EQ(2.0, Calculator::Divide(-6, -3));
    EXPECT_DOUBLE_EQ(-2.5, Calculator::Divide(-5, 2));
}

TEST(CalculatorTest, Divide_ByZero)
{
    EXPECT_THROW(Calculator::Divide(5, 0), std::invalid_argument);
}

// ============================================================================
// Main 函數 - Google Test 入口點
// ============================================================================
int main(int argc, char** argv)
{
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
