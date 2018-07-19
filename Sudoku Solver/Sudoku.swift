//
//  Sudoku.swift
//  Sudoku Solver
//
//  Created by 남상규 on 2018. 7. 5..
//  Copyright © 2018년 NeoLogic. All rights reserved.
//

import Foundation

// number가 현재 cell에 맞는지 검사
func isValid(_ number: Int, _ sudoku: [[Int]], _ row: Int, _ col:Int) -> Bool {
    let sectorRow: Int = 3 * Int(row / 3)
    let sectorCol: Int = 3 * Int(col / 3)
    let row1 = (row + 2) % 3
    let row2 = (row + 4) % 3
    let col1 = (col + 2) % 3
    let col2 = (col + 4) % 3

    // number가 row, column에 존재하는지 검사
    for i in 0..<9 {
        if (sudoku[i][col] == number) {
            return false
        }
        if (sudoku[row][i] == number) {
            return false
        }
    }

    // cell이 속한 section의 나머지 4 귀퉁이 cell에도 같은 숫자가 있는지 검사
    if (sudoku[row1 + sectorRow][col1 + sectorCol] == number) {
        return false
    }
    if (sudoku[row2 + sectorRow][col1 + sectorCol] == number) {
        return false
    }
    if (sudoku[row1 + sectorRow][col2 + sectorCol] == number) {
        return false
    }
    if (sudoku[row2 + sectorRow][col2 + sectorCol] == number) {
        return false
    }

    // 모든 것을 통과! valid!
    return true
}

func sudoku_solver(_ sudoku: inout [[Int]], _ row: Int, _ col: Int) -> Bool {
    if (row == 9) {
        return true
    }

    // cell에 이미 숫자가 있는 경우는 변경하지 않고 바로 다음 cell로 넘어감
    if (sudoku[row][col] != 0) {
        if (col == 8) {
            if (sudoku_solver(&sudoku, row+1, 0) == true) {
                return true
            }
        } else {
            if (sudoku_solver(&sudoku, row, col+1) == true) {
                return true
            }
        }
        return false
    }

    // interation을 돈다
    for nextNum in 1..<10 {
        if (isValid(nextNum, sudoku, row, col) == true) {
            sudoku[row][col] = nextNum
            if (col == 8) {
                if (sudoku_solver(&sudoku, row+1, 0) == true) {
                    return true
                }
            } else {
                if (sudoku_solver(&sudoku, row, col+1) == true) {
                    return true
                }
            }
            // 이 cell에 대해 valid value를 찾지 못함
            sudoku[row][col] = 0
        }
    }
    
    return false
}

