# WaterfallLayout (UIKit)

`UICollectionViewLayout`을 직접 구현한 워터폴 레이아웃입니다.  
Self-sizing 셀과 부분 invalidate를 안정적으로 처리하는 것을 목표로 했습니다.

---

## Why Custom Layout?

이 구현은 **컬럼별 누적 높이를 기준으로 아이템을 배치하는 워터폴 알고리즘**을 전제로 합니다.

FlowLayout과 CompositionalLayout은 모두:

- Row 기반 배치 모델
- 선언형 그룹 구성 방식

을 전제로 하며,

> “현재 가장 낮은 컬럼에 다음 아이템을 배치”하는  
> 누적 계산 기반 전략을 직접 제어하기 어렵습니다.

FlowLayout을 subclassing하는 방법도 고려했지만,

- 기본 row 기반 geometry를 대부분 무시하게 되고
- layoutAttributes를 재계산해야 하며
- invalidate 제어가 제한적입니다.

따라서 배치 전략과 invalidate 범위를 완전히 통제하기 위해  
`UICollectionViewLayout`을 직접 구현했습니다.

---

## Core Concepts

### 1. Column-based Placement

- 섹션별 컬럼 상태 유지
- 가장 낮은 컬럼에 아이템 배치
- 이전 섹션의 maxY를 기준으로 시작점 계산
- 컬렉션 너비 변경 시 metric 재계산

---

### 2. Cache-first Strategy

- `layoutAttributesDictionary` 기반 캐시
- 필요한 구간부터 attributes 생성
- `prepare()`는 가능한 가볍게 유지

---

### 3. Partial Invalidation

Custom `UICollectionViewLayoutInvalidationContext`를 통해  
invalidate를 원인 기반으로 분리했습니다.

- `fullReset`
- `dataChanged(minIndexPath:)`
- `selfSizingChanged(indexPath:)`
- `reconcile`

Self-sizing으로 특정 아이템 높이가 변경되면  
해당 indexPath 이후 아이템만 재배치합니다.

---

### 4. Custom LayoutAttributes

- `column` 메타데이터 추가
- `copy(with:)`, `isEqual(_:)` 구현
- 캐시 원본 대신 복사본 반환

---

## What This Demonstrates

- `UICollectionViewLayout` 기반 커스텀 레이아웃 설계
- invalidate 사이클 제어
- self-sizing 연쇄 재배치 처리
- 캐시 기반 성능 고려
