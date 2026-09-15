.PHONY: generate build open acceptance notes

generate:
	xcodegen generate

build: generate
	xcodebuild -project LocusCal.xcodeproj -scheme LocusCal -configuration Debug \
		CODE_SIGN_IDENTITY="-" CODE_SIGNING_ALLOWED=YES build

open: generate
	open LocusCal.xcodeproj

acceptance notes:
	@sed -n '1,120p' ACCEPTANCE.md
