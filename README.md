# gwacheonhs-api ![](https://github.com/ChemistryX/gwacheonhs-api/workflows/deploy-prod/badge.svg)

과천고등학교 REST API입니다. [과천고등학교 애플리케이션](https://github.com/ChemistryX/gwacheonhs_app)에 사용되기 위해 만들어졌으며 [Ruby on Jets](https://github.com/boltops-tools/jets)를 사용하여 [AWS Lambda](https://aws.amazon.com/lambda/)에서 서비스되고 있습니다.

## 기능

```
공지사항 목록 JSON 변환
공지사항 게시물 내용 JSON 변환
컴시간 시간표 크롤링 & Firebase에 저장 [Deprecated]
학사 일정 및 급식 정보 나이스에서 파싱 [Deprecated]
```

## 설치하기

`참고` [Ruby 2.5](https://www.ruby-lang.org)이상이 설치되어 있어야 합니다.

```
bundle install
```

## 실행하기

```
jets server
```

## 배포하기

```
jets deploy prod
```
